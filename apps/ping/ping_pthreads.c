#include <semaphore.h>
#include <pthread.h>
#include <stdio.h>

sem_t pingsem, pongsem;

#define M 10000000

void *
ping(void *arg) 
{
    unsigned int i;
    for (i=0;i<M;i++) {
        sem_wait(&pingsem);
        //printf("ping\n");
        sem_post(&pongsem);
    }
}

void *
pong(void *arg) 
{
    unsigned int i;
    for (i=0;i<M;i++) {
        sem_wait(&pongsem);
        //printf("pong\n");
        sem_post(&pingsem);
    }
}

int 
main(void) 
{
    sem_init(&pingsem, 0, 0);
    sem_init(&pongsem, 0, 1);
    pthread_t ping_thread, pong_thread; 
    pthread_create(&ping_thread, NULL, ping, NULL);
    pthread_create(&pong_thread, NULL, pong, NULL);
    pthread_join(ping_thread, NULL);
    pthread_join(pong_thread, NULL);
    return 0;
}
