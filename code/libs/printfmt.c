/* printfmt.c —— 格式化引擎：只负责解析格式串，输出目标由调用者的 putch 回调决定。
   支持 %c %s %d %u %o %x %p %% 与 %e（打印错误码文字）；宽度/填充只对数字生效。 */
#include <defs.h>
/* 包含 riscv.h 是为了其中的 do_div 宏——printnum 逐位取数字要靠它。 */
#include <riscv.h>
#include <error.h>
#include <stdio.h>
#include <string.h>

/* *
 * Space or zero padding and a field width are supported for the numeric
 * formats only.
 *
 * The special format %e takes an integer error code
 * and prints a string describing the error.
 * The integer may be positive or negative,
 * so that -E_NO_MEM and E_NO_MEM are equivalent.
 * */

/* 错误码→文字对照表。下标就是 error.h 的错误码，两处必须同步修改。 */
static const char * const error_string[MAXERROR + 1] = {
/* [0] 是占位 NULL；[E_XXX]= 写法是 C99 指定初始化器，码不连续也不会填错位置。 */
    [0]                        NULL,
    [E_UNSPECIFIED]            "unspecified error",
    [E_BAD_PROC]            "bad process",
    [E_INVAL]                "invalid parameter",
    [E_NO_MEM]                "out of memory",
    [E_NO_FREE_PROC]        "out of processes",
    [E_FAULT]                "segmentation fault",
};

/* *
 * printnum - print a number (base <= 16) in reverse order
 * @putch:        specified putch function, print a single character
 * @putdat:        used by @putch function
 * @num:        the number will be printed
 * @base:        base for print, must be in [1, 16]
 * @width:         maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:        character that padded on the left if the actual width is less than @width
 * */
/* printnum：递归打印（先高位后低位）。do_div 返回最低位数字，并把商写回 result。 */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);

    // first recursively print all preceding (more significant) digits
/* 还有更高位就带 width-1 递归；否则先补足宽度，再打印当前这一位。 */
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
            putch(padc, putdat);
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
}

/* *
 * getuint - get an unsigned int of various possible sizes from a varargs list
 * @ap:            a varargs list pointer
 * @lflag:        determines the size of the vararg that @ap points to
 * */
/* getuint：按 lflag（0 / 1 / ≥2 对应 %u / %lu / %llu）取不同宽度的无符号值。 */
static unsigned long long
getuint(va_list *ap, int lflag) {
    if (lflag >= 2) {
        return va_arg(*ap, unsigned long long);
    }
    else if (lflag) {
        return va_arg(*ap, unsigned long);
    }
    else {
        return va_arg(*ap, unsigned int);
    }
}

/* *
 * getint - same as getuint but signed, we can't use getuint because of sign extension
 * @ap:            a varargs list pointer
 * @lflag:        determines the size of the vararg that @ap points to
 * */
/* getint：有符号版。不能复用 getuint，否则负数会被当成巨大的正数。 */
static long long
getint(va_list *ap, int lflag) {
    if (lflag >= 2) {
        return va_arg(*ap, long long);
    }
    else if (lflag) {
        return va_arg(*ap, long);
    }
    else {
        return va_arg(*ap, int);
    }
}

/* *
 * printfmt - format a string and print it by using putch
 * @putch:        specified putch function, print a single character
 * @putdat:        used by @putch function
 * @fmt:        the format string to use
 * */
/* printfmt：变参入口，直接转交 vprintfmt。 */
void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
    va_list ap;

    va_start(ap, fmt);
    vprintfmt(putch, putdat, fmt, ap);
    va_end(ap);
}

/* vprintfmt：全部格式解析都在这里。外层循环反复处理“一段普通文本 + 一个格式项”。 */
/* *
 * vprintfmt - format a string and print it by using putch, it's called with a va_list
 * instead of a variable number of arguments
 * @putch:        specified putch function, print a single character
 * @putdat:        used by @putch function
 * @fmt:        the format string to use
 * @ap:            arguments for the format string
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
    register const char *p;
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
/* 原样输出普通字符直到 '%'，'\0' 即结束。强转 unsigned char 可避免高位字节被判成负数。 */
        while ((ch = *(unsigned char *)fmt ++) != '%') {
            if (ch == '\0') {
                return;
            }
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

/* reswitch：每读完一个修饰符就跳回这里，继续读下一个。 */
    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {

/* '-' 只是把填充字符换成 '-'：对 %s 是左对齐，对数字则是用 '-' 左填充（%-5d → ----3）。 */
        // flag to pad on the right
        case '-':
            padc = '-';
            goto reswitch;

        // flag to pad with 0's instead of spaces
        case '0':
            padc = '0';
            goto reswitch;

/* 宽度先存进 precision，由 process_precision 决定它是宽度还是精度；
   case '1' ... '9' 是 GNU 区间 case 扩展，标准 C 不支持。 */
        // width field
        case '1' ... '9':
            for (precision = 0; ; ++ fmt) {
                precision = precision * 10 + ch - '0';
                ch = *fmt;
                if (ch < '0' || ch > '9') {
                    break;
                }
            }
            goto process_precision;

        case '*':
            precision = va_arg(ap, int);
            goto process_precision;

        case '.':
            if (width < 0)
                width = 0;
            goto reswitch;

        case '#':
            altflag = 1;
            goto reswitch;

/* process_precision：宽度尚未确定时把它当宽度；其余留在 precision。
   本实现里精度对整数无效（printnum 只收宽度），只有 %s 会用 precision 截断。 */
        process_precision:
            if (width < 0)
                width = precision, precision = -1;
            goto reswitch;

        // long flag (doubled for long long)
/* 'l' 出现 1 次表示 long，2 次（ll）表示 long long，决定从变参里取多宽。 */
        case 'l':
            lflag ++;
            goto reswitch;

        // character
        case 'c':
            putch(va_arg(ap, int), putdat);
            break;

        // error message
/* %e：错误码取绝对值后查 error_string；越界或表项为空时退化成打印 "error N"。 */
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
                printfmt(putch, putdat, "error %d", err);
            }
            else {
                printfmt(putch, putdat, "%s", p);
            }
            break;

        // string
/* %s：NULL 打 "(null)"；宽度用于补齐、precision 用于截断；带 '#' 时不可打印字符变 '?'。 */
        case 's':
            if ((p = va_arg(ap, char *)) == NULL) {
                p = "(null)";
            }
            if (width > 0 && padc != '-') {
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
                if (altflag && (ch < ' ' || ch > '~')) {
                    putch('?', putdat);
                }
                else {
                    putch(ch, putdat);
                }
            }
            for (; width > 0; width --) {
                putch(' ', putdat);
            }
            break;

        // (signed) decimal
/* %d：先输出 '-' 再取相反数，之后与其它进制共用 number 出口。 */
        case 'd':
            num = getint(&ap, lflag);
            if ((long long)num < 0) {
                putch('-', putdat);
                num = -(long long)num;
            }
            base = 10;
            goto number;

        // unsigned decimal
        case 'u':
            num = getuint(&ap, lflag);
            base = 10;
            goto number;

        // (unsigned) octal
        case 'o':
            num = getuint(&ap, lflag);
            base = 8;
            goto number;

        // pointer
        case 'p':
            putch('0', putdat);
            putch('x', putdat);
            num = (unsigned long long)va_arg(ap, void *);
            base = 16;
            goto number;

        // (unsigned) hexadecimal
/* %x 与 %u/%o/%p 共用 number 出口：printnum 按 (num, base, width, padc) 输出。 */
        case 'x':
            num = getuint(&ap, lflag);
            base = 16;
        number:
            printnum(putch, putdat, num, base, width, padc);
            break;

        // escaped '%' character
        case '%':
            putch(ch, putdat);
            break;

/* 未识别的转义序列：回退 fmt，使 '%' 与那个未知字符都被原样输出。 */
        // unrecognized escape sequence - just print it literally
        default:
            putch('%', putdat);
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}

/* sprintbuf is used to save enough information of a buffer */
/* sprintbuf：面向内存的输出状态；cnt 统计“本应写入”的长度。 */
struct sprintbuf {
    char *buf;            // address pointer points to the first unused memory
    char *ebuf;            // points the end of the buffer
    int cnt;            // the number of characters that have been placed in this buffer
};

/* *
 * sprintputch - 'print' a single character in a buffer
 * @ch:            the character will be printed
 * @b:            the buffer to place the character @ch
 * */
static void
/* cnt 无条件自增，只在有空间时才真正写——这样 snprintf 才能返回截断前的长度。 */
sprintputch(int ch, struct sprintbuf *b) {
    b->cnt ++;
    if (b->buf < b->ebuf) {
        *b->buf ++ = ch;
    }
}

/* *
 * snprintf - format a string and place it in a buffer
 * @str:        the buffer to place the result into
 * @size:        the size of buffer, including the trailing null space
 * @fmt:        the format string to use
 * */
int
/* snprintf：转交 vsnprintf。 */
snprintf(char *str, size_t size, const char *fmt, ...) {
    va_list ap;
    int cnt;
    va_start(ap, fmt);
    cnt = vsnprintf(str, size, fmt, ap);
    va_end(ap);
    return cnt;
}

/* *
 * vsnprintf - format a string and place it in a buffer, it's called with a va_list
 * instead of a variable number of arguments
 * @str:        the buffer to place the result into
 * @size:        the size of buffer, including the trailing null space
 * @fmt:        the format string to use
 * @ap:            arguments for the format string
 *
 * The return value is the number of characters which would be generated for the
 * given input, excluding the trailing '\0'.
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want snprintf() instead.
 * */
int
/* vsnprintf：ebuf 取 str+size-1，给结尾 '\0' 永久留一字节；容量不足返回 -E_INVAL。 */
vsnprintf(char *str, size_t size, const char *fmt, va_list ap) {
    struct sprintbuf b = {str, str + size - 1, 0};
    if (str == NULL || b.buf > b.ebuf) {
        return -E_INVAL;
    }
    // print the string to the buffer
/* 复用同一个引擎，只把输出目标换成 sprintputch。 */
    vprintfmt((void*)sprintputch, &b, fmt, ap);
    // null terminate the buffer
/* 写终止符；返回“本应写入”的字符数，可用于判断是否被截断。 */
    *b.buf = '\0';
    return b.cnt;
}

