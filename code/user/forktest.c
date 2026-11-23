#include <stdio.h>
#include <ulib.h>

#define N 4

int
main(void)
{
    int pid, code;
    for (int i = 0; i < N; i++)
    {
        if ((pid = fork()) == 0)
        {
            cprintf("child %d.\n", i);
            exit(0);
        }
        assert(pid > 0);
    }

    for (int i = 0; i < N; i++)
    {
        assert(wait(&code) == 0 && code == 0);
    }
    cprintf("forktest pass.\n");
    return 0;
}
