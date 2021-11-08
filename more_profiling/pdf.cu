/*----------------------------------------------------------------------
Program pdf0.c computes a pair distribution function for n atoms
given the 3D coordinates of the atoms.
----------------------------------------------------------------------*/
#include <stdio.h>
#include <math.h>
#include <time.h>
#include <stdlib.h>
#include <cuda.h>

#define NHBIN 2000  // Histogram size

float al[3];        // Simulation box lengths
int n;              // Number of atoms
float *r;           // Atomic position array
FILE *fp;

__constant__ float DALTH[3];
__constant__ int DN;
__constant__ float DDRH;

//float SignR(float v,float x) {if (x > 0) return v; else return -v;}
__device__ float d_SignR(float v,float x) {if (x > 0) return v; else return -v;}

__global__ void gpu_histogram_kernel(float *r,float *nhis) {
  int i,j,a,ih;
  float rij,dr;

  int iBlockBegin = (DN/gridDim.x)*blockIdx.x;
  int iBlockEnd = (DN/gridDim.x)*(blockIdx.x+1);
  if (blockIdx.x == gridDim.x-1) iBlockEnd = DN;

  int jBlockBegin = (DN/gridDim.y)*blockIdx.y;
  int jBlockEnd = (DN/gridDim.y)*(blockIdx.y+1);
  if (blockIdx.y == gridDim.y-1) jBlockEnd = DN;

  for (i=iBlockBegin+threadIdx.x; i<iBlockEnd; i+=blockDim.x) {
    for (j=jBlockBegin+threadIdx.y; j<jBlockEnd; j+=blockDim.y) {
      if (i<j) {
        // Process (i,j) atom pair
        rij = 0.0;
        for (a=0; a<3; a++) {
          dr = r[3*i+a]-r[3*j+a];
          /* Periodic boundary condition */
          dr = dr-d_SignR(DALTH[a],dr-DALTH[a])-d_SignR(DALTH[a],dr+DALTH[a]);
          rij += dr*dr;
        }
        rij = sqrt(rij); /* Pair distance */
        ih = rij/DDRH;
        //nhis[ih] += 1.0;
        atomicAdd(&nhis[ih],1.0);
      } // end if i<j
    } // end for j
  } // end for i

}
/*--------------------------------------------------------------------*/
void histogram() {
/*----------------------------------------------------------------------
Constructs a histogram NHIS for atomic-pair distribution.
----------------------------------------------------------------------*/
  float alth[3];
  float* nhis;  // Histogram array
  float rhmax,drh,dr,rij,density,gr;
  int a,ih,i,j;  

  float* dev_r;     // Atomic positions
  float* dev_nhis;  // Histogram

  /* Half the simulation box size */
  for (a=0; a<3; a++) alth[a] = 0.5*al[a];
  /* Max. pair distance RHMAX & histogram bin size DRH */
  rhmax = sqrt(alth[0]*alth[0]+alth[1]*alth[1]+alth[2]*alth[2]);
  drh = rhmax/NHBIN;  // Histogram bin size

  nhis = (float*)malloc(sizeof(float)*NHBIN);
//for (ih=0; ih<NHBIN; ih++) nhis[ih] = 0.0; // Reset the histogram
  cudaMalloc((void**)&dev_r,sizeof(float)*3*n);
  cudaMalloc((void**)&dev_nhis,sizeof(float)*NHBIN);

  cudaMemcpy(dev_r,r,3*n*sizeof(float),cudaMemcpyHostToDevice);
  cudaMemset(dev_nhis,0.0,NHBIN*sizeof(float));

  cudaMemcpyToSymbol(DALTH,alth,sizeof(float)*3,0,cudaMemcpyHostToDevice);
  cudaMemcpyToSymbol(DN,&n,sizeof(int),0,cudaMemcpyHostToDevice);
  cudaMemcpyToSymbol(DDRH,&drh,sizeof(float),0,cudaMemcpyHostToDevice);

  dim3 numBlocks(8,8,1);
  dim3 threads_per_block(16,16,1);
  gpu_histogram_kernel<<<numBlocks,threads_per_block>>>(dev_r,dev_nhis);

  cudaMemcpy(nhis,dev_nhis,NHBIN*sizeof(float),cudaMemcpyDeviceToHost);
  cudaFree(dev_r);
  cudaFree(dev_nhis);

  density = n/(al[0]*al[1]*al[2]);
  /* Print out the histogram */
  fp = fopen("pdf.d","w");
  for (ih=0; ih<NHBIN; ih++) {
    gr = nhis[ih]/(2*M_PI*pow((ih+0.5)*drh,2)*drh*density*n);
    fprintf(fp,"%e %e\n",(ih+0.5)*drh,gr);
  }
  fclose(fp);
  free(nhis);
}

/*--------------------------------------------------------------------*/
int main() {
/*--------------------------------------------------------------------*/
  int i;
  float cpu1,cpu2;

  /* Read the atomic position data */
  fp = fopen("pos.d","r");
  fscanf(fp,"%f %f %f",&(al[0]),&(al[1]),&(al[2]));
  fscanf(fp,"%d",&n);
  r = (float*)malloc(sizeof(float)*3*n);
  for (i=0; i<n; i++)
    fscanf(fp,"%f %f %f",&(r[3*i]),&(r[3*i+1]),&(r[3*i+2]));
  fclose(fp);

  /* Compute the histogram */
  cpu1 = ((float) clock())/CLOCKS_PER_SEC;
  histogram();  
  cpu2 = ((float) clock())/CLOCKS_PER_SEC;
  printf("Execution time (s) = %le\n",cpu2-cpu1);

  free(r);
  return 0;
}
