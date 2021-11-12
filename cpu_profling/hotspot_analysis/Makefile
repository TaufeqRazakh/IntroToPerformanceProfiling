CFLAGS = -vec -O2 -g -qopenmp -qopenmp-simd
CC = icx

singlethreaded_pi_calc: pi.o
	$(CC) -o $@ $^ $(CFLAGS)

multithreaded_pi_calc: omp_pi.o
	$(CC) -o $@ $^ $(CFLAGS)
	
.PHONY: clean
clean:
	rm -f *.o *_pi_calc
