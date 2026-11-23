#include <stdio.h>
#include <ulib.h>

int
main(void)
{
    int pid = fork();
    if (pid == 0)
    {
        while (1)
        {
            yield();
        }
    }
    assert(pid > 0);

    assert(kill(pid) == 0);
    int code;
    assert(waitpid(pid, &code) == 0);
    assert(code == -8);         /* -E_KILLED */
    cprintf("waitkill pass.\n");
    return 0;
}
