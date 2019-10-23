#include <stdio.h>
#include <uv.h>

#define M 10000000

uv_sem_t pingsem, pongsem;

void reader(void *n)
{
    int i;
    for (i = 0; i < M; i++) {
        uv_sem_wait(&pingsem);
	/* ping */
	uv_sem_post(&pongsem);
    }
}

void writer(void *n)
{
    unsigned int i;
    for (i=0;i<M;i++) {
        uv_sem_wait(&pongsem);
        /* pong */
        uv_sem_post(&pingsem);
    }
}

int main()
{
    uv_thread_t threads[3];

    uv_sem_init(&pingsem, 0);
    uv_sem_init(&pongsem, 1);

    int thread_nums[] = {1, 2};
    uv_thread_create(&threads[0], reader, &thread_nums[0]);
    uv_thread_create(&threads[1], writer, &thread_nums[1]);

    uv_thread_join(&threads[0]);
    uv_thread_join(&threads[1]);

    return 0;
}
