#include <stdio.h>
#include <ulib.h>

int
main(void)
{
    for (int i = 0; i < 10; i++)
    {
        cprintf("yield %d.\n", i);
        yield();
    }
    cprintf("yield pass.\n");
    return 0;
}
