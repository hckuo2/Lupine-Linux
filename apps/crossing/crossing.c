#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#define ONE_MILLION 1000000
#define ONE_BILLION 1000000000

int main(int argc, const char* argv[]) {
	unsigned int busy_waiting_cnt;
	if (argc == 2)
		busy_waiting_cnt = atoi(argv[1]);
	else
		busy_waiting_cnt = 0;

	unsigned int COUNT = 10 * ONE_MILLION;

	struct timespec ts_start;
	struct timespec ts_end;

	clock_gettime(CLOCK_MONOTONIC, &ts_start);

	unsigned int i;
	for(i = 0; i < COUNT; i++) {
		getppid();
		unsigned int j;
		for(j = 0; j < busy_waiting_cnt; j++) {}
	}

	clock_gettime(CLOCK_MONOTONIC, &ts_end);

	unsigned long elapsed_nanosecs = (ts_end.tv_nsec - ts_start.tv_nsec)
		+ (ts_end.tv_sec - ts_start.tv_sec) * ONE_BILLION;
	printf("Elapsed_time: %lu Crossing_Rate: %f\n", elapsed_nanosecs,
			(double)COUNT/elapsed_nanosecs*ONE_BILLION);

	return 0;
}
