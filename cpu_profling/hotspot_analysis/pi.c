#include <stdio.h>
#define NBIN 10000000
int main() {
	long long i;
	double step,x,sum=0.0,pi;

	step = 1.0/NBIN;
	for (i=0; i<NBIN; i++) {
		x = (i+0.5)*step;
		sum += 4.0/(1.0+x*x);
	}
	pi = sum*step;
	printf("PI = %f\n",pi);
	return 0;
}
