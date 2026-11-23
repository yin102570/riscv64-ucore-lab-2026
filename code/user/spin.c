#include <stdio.h>
#include <ulib.h>

int
main(void)
{
    int pid = fork();
    if (pid == 0)
    {
        /* Never yields: only the timer interrupt can take the CPU away. */
        while (1)
        {
            ;
        }
    }
    assert(pid > 0);

    yield();
    yield();
    yield();
    assert(kill(pid) == 0);
    assert(wait(NULL) == 0);
    cprintf("spin pass.\n");
    return 0;
}
