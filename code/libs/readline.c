/* readline —— 逐字符读入一整行（轮询 getchar），带回显与退格处理。 */
#include <stdio.h>

/* 单行上限 1024 字节，超出的字符被丢弃（不回显、不入缓冲）。 */
#define BUFSIZE 1024
/* ⚠ 返回的是这个全局静态缓冲区，下次调用会被覆盖：要保留请先复制走。 */
static char buf[BUFSIZE];

/* *
 * readline - get a line from stdin
 * @prompt:        the string to be written to stdout
 *
 * The readline() function will write the input string @prompt to
 * stdout first. If the @prompt is NULL or the empty string,
 * no prompt is issued.
 *
 * This function will keep on reading characters and saving them to buffer
 * 'buf' until '\n' or '\r' is encountered.
 *
 * Note that, if the length of string that will be read is longer than
 * buffer size, the end of string will be discarded.
 *
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *readline(const char *prompt) {
/* prompt 为 NULL 或空串时不输出提示。 */
    if (prompt != NULL) {
        cprintf("%s", prompt);
    }
    int i = 0, c;
/* 主循环：getchar() 会一直忙等到有输入才返回。 */
    while (1) {
        c = getchar();
/* 负值视为出错，直接返回 NULL。 */
        if (c < 0) {
            return NULL;
/* 可打印字符：先回显再存入；i < BUFSIZE-1 是给结尾的 '\0' 留一个字节。 */
        } else if (c >= ' ' && i < BUFSIZE - 1) {
            cputchar(c);
            buf[i++] = c;
/* 退格：回显 '\b' 让光标左移，并把 i 减一。 */
        } else if (c == '\b' && i > 0) {
            cputchar(c);
            i--;
/* '\n' 或 '\r' 结束本行：写终止符后返回 buf。 */
        } else if (c == '\n' || c == '\r') {
            cputchar(c);
            buf[i] = '\0';
            return buf;
        }
    }
}
