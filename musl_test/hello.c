#include <sys/types.h>
#include <unistd.h>
#include <stdio.h>

int main(int argc, char **argv)
{
    pid_t pid = getpid();
    pid_t pgid = getpgid(pid);
    printf("hello\n");
    printf("my pid is %d\n", pid);
    printf("my pgid is %d\n", pgid);
    return 0;
}
