#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdint.h>
#include <linux/random.h>
#include <fcntl.h>
#include <sys/ioctl.h>


uint8_t prng(void) {
    static uint8_t seed=19;
    seed = 311 * seed + 17;
    return seed;
}

#define BUF_SIZE 256
#define MAX_ITERS 10000

int main(int argc, char **argv)
{
    struct rand_pool_info *output;
    int max_iters = MAX_ITERS;
    int iters = 0, ret;
	int fd = open("/dev/random", O_WRONLY);

    if (argc == 2)
        max_iters = atoi(argv[1]);
    
    printf("generating \"entropy\"...");
    output = (struct rand_pool_info *)malloc(sizeof(struct rand_pool_info)
                                             + BUF_SIZE);
	do {
        int i;
        output->entropy_count = BUF_SIZE * 8;
        output->buf_size = BUF_SIZE;
        for (i=0; i< BUF_SIZE; i++)
            output->buf[i] = prng();
        ret = ioctl(fd, RNDADDENTROPY, &output);
        iters++;
    } while((ret >= 0) && (iters < max_iters));

    printf("for %d iters\n", iters);
}
