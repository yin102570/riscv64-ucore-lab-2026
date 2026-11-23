#ifndef __USER_LIBS_ULIB_H__
#define __USER_LIBS_ULIB_H__

#include <defs.h>
#include <stdio.h>

void exit(int error_code);
int fork(void);
int wait(int *store);
int waitpid(int pid, int *store);
void yield(void);
int kill(int pid);
int getpid(void);
void pgdir(void);

void __panic(const char *file, int line, const char *fmt, ...);

#define assert(x)                                                      \
    do {                                                               \
        if (!(x)) {                                                    \
            cprintf("assertion failed: %s (%s:%d)\n", #x, __FILE__,    \
                    __LINE__);                                         \
            exit(-1);                                                  \
        }                                                              \
    } while (0)

#endif /* !__USER_LIBS_ULIB_H__ */
