# Vtune & Nsight Profiling
CSCI 596: Scientific Computing and Visualization

## Pre-requisite - Installing the profiler GUI
Download & install the latest version of the Intel oneAPI Vtune Profiler GUI from this [link](https://www.intel.com/content/www/us/en/developer/tools/oneapi/vtune-profiler-download.html).

Upon installation, launch the GUI from the installation directory depending on your OS.
- windows: [Program Files]\Intel\oneAPI\vtune\<version>
- Linux OS: /opt/intel/oneapi/vtune/\<version>
- mac OS: /opt/intel/oneapi/vtune_profiler/\<version>

Download and install the latest version of Intel Advisor [here](https://www.intel.com/content/www/us/en/developer/articles/tool/oneapi-standalone-components.html#advisor)

Upon installation, launch the GUI from from the installation directory depending on your OS.
- windows: [Program Files]\Intel\oneAPI\advisor\<version>
- Linux OS: /opt/intel/oneapi/advisor/\<version>
- mac OS: /opt/intel/oneapi/advisor/\<version>

## CPU profiling with Vtune

The purpose of profiling is to gain insight into the performance of a program while it runs on a given architecture.
We will first try to understand how to carry out profiling on CPU's and then move on on GPU's.

Today's steps should give you an idea about how to carry out algorithm(hotspot), microarchitecture(memory access) and parallelism(threading) analysis for different architectures.

[Intel® VTune™](https://www.intel.com/content/www/us/en/develop/documentation/vtune-help/top.html) is one of the many profiler tools that is suitable for analyzing multithreaded applications on CPU's (well...not just CPU, but for the scope of this discussion we will limit  VTune's application to CPU execution).

> Some examples of other available profilers
- [Tau](http://www.cs.uoregon.edu/research/tau/home.php)
- [Arm Map](https://www.arm.com/products/development-tools/server-and-hpc/forge/map) $$$
- [HPC Toolkit](http://hpctoolkit.org/)
- [PAPI](http://icl.cs.utk.edu/papi/)

> How does a profiler work ?
They make use of the performance counter hardware that is in-built to the architecture

The directory [cpu_profiling](/cpu_profiling) has the source code to calculate pi over 100000 bins.

We provide a `Makefile` with rules to build the binaries for serial (single threaded) and parallel (multi threaded) calculation of pi. You are already familiar with the these codes from previous assignments.

For VTune analysis applications must be compiled with the Intel® Compiler, we can invoke the suitable compiler by loading the load the necessary modules - `intel-oneapi` on discovery cluster with the following commands.

```
salloc -n 1 -p debug
module load intel-oneapi
```

We can now build the binaries with the following `make` commands.

```
make singlethreaded_pi_calc
make multithreaded_pi_calc
export OMP_NUM_THREADS=2
```

You should have two executables in your working directory.

Try executing the binaries and see if you get the value of pi

```
$./singlethreaded_pi_calc
PI = 3.141593
$ ./multithreaded_pi_calc
PI = 3.141593
```

Get a profile report with the following commands
```
vtune -collect hotspots -result-dir rSingleThread ./singlethreaded_pi_calc
vtune -collect hotspots -result-dir rMultiThread ./multithreaded_pi_calc
vtune -collect memory-consumption -result-dir rMultiMemory ./multithreaded_pi_calc

```
This will result in the creation of two reports named `rSingleThread`, `rMultiThread`, `rMultiMemory`. Import the the files to your local machine to view the results.

> To quickly view the results from the command line try
```
vtune -report summary -result-dir rSingleThread/
vtune -report summary -result-dir rMultiThread/
```

We prefer using the GUI for analysis since it is feature rich and helps in top which help in code and performance analysis. Launch the GUI as listed in the pre-requisite section.

To load the profile report click on the three lines displayed on the left bar and select open > Result > \<your report file>

## Inferences
![omp_2_thread_summary](img/omp_2_thread_summary.png)
We see that a total of 2 threads are created in the execution
![omp_2_thread_activity](img/omp_2_thread_activity.png)
We can analyse the activity of the threads that we create
![omp_2_function_memory_allocation](img/omp_2_function_memory_allocation.png)
We also see the memory allocations and deallocations happening across the call stack.

## Roofline analysis with advisor

in the same working directory as before, type in the following command

```
 advixe-cl -collect roofline -project-dir roofline_analysis ./multithreaded_pi_calc
```

Import the report to your local machine and view it with the Advisor GUI.



Next we will study accelerator analysis(GPU offload).  
