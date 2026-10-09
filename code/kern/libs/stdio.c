/* kern/libs/stdio.c —— 内核高层输出/输入：向下调 console.h，格式化交给 libs/printfmt.c。 */
#include <console.h>
#include <defs.h>
#include <stdio.h>

/* HIGH level console I/O */

/* cputch：适配 printfmt 要求的 putch 回调，并累加已输出字符数。 */
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void cputch(int c, int *cnt) {
    cons_putc(c);
    (*cnt)++;
}

/* vcprintf：把 cputch 交给 vprintfmt 引擎，返回写出的字符数。 */
/* *
 * vcprintf - format a string and writes it to stdout
 *
 * The return value is the number of characters which would be
 * written to stdout.
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap) {
    int cnt = 0;
/* (void *) 强转是因为 cputch 的第二参数是 int*，而接口约定为 void*。 */
    vprintfmt((void *)cputch, &cnt, fmt, ap);
    return cnt;
}

/* cprintf：变参入口，标准三步 va_start → vcprintf → va_end。 */
/* *
 * cprintf - formats a string and writes it to stdout
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...) {
    va_list ap;
    int cnt;
    va_start(ap, fmt);
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}

/* cputchar：直接输出，不经格式化。 */
/* cputchar - writes a single character to stdout */
void cputchar(int c) { cons_putc(c); }

/* cputs：末尾会额外补一个换行符（与标准 puts 一致），返回值含这个换行。 */
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int cputs(const char *str) {
    int cnt = 0;
    char c;
    while ((c = *str++) != '\0') {
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}

/* getchar：忙等直到 cons_getc() 返回非 0（0 表示暂无输入）。 */
/* getchar - reads a single non-zero character from stdin */
int getchar(void) {
    int c;
    while ((c = cons_getc()) == 0) /* do nothing */;
    return c;
}
