/* stdio.h —— 打印/输入函数声明。实现分在三处：kern/libs/stdio.c、libs/readline.c、libs/printfmt.c。 */
#ifndef __LIBS_STDIO_H__
#define __LIBS_STDIO_H__

#include <defs.h>
#include <stdarg.h>

/* kern/libs/stdio.c */
/* 内核高层输出/输入；getchar 内部忙等，直到读到非 0 值才返回。 */
int cprintf(const char *fmt, ...);
int vcprintf(const char *fmt, va_list ap);
void cputchar(int c);
int cputs(const char *str);
int getchar(void);

/* libs/readline.c */
/* 读一整行；返回内部静态缓冲区，下次调用会覆盖。 */
char *readline(const char *prompt);

/* libs/printfmt.c */
/* 真正的格式化引擎：输出目标由调用者传入的 putch 回调决定。 */
void printfmt(void (*putch)(int, void *), void *putdat, const char *fmt, ...);
void vprintfmt(void (*putch)(int, void *), void *putdat, const char *fmt, va_list ap);
int snprintf(char *str, size_t size, const char *fmt, ...);
int vsnprintf(char *str, size_t size, const char *fmt, va_list ap);

#endif /* !__LIBS_STDIO_H__ */

