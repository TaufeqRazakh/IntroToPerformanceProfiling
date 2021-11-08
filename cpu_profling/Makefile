CFLAGS = -fopenmp

singlethreaded_pi_calc: pi.o
	$(CC) -o $@ $^

multithreaded_pi_calc: omp_pi.o
	$(CC) -o $@ $^ $(CFLAGS)
	
.PHONY: clean
clean:
	rm -f *.o *_pi_calc