/* kern_init —— entry.S 用 tail 跳到这里，是内核的 C 语言入口。 */
#include <stdio.h>
#include <string.h>
#include <sbi.h>
/* noreturn：告诉编译器本函数永不返回，entry.S 才敢用不保存 ra 的 tail 跳转。 */
int kern_init(void) __attribute__((noreturn));

/* 本阶段只做两件事：清 .bss、打印横幅，然后死循环停住。 */
int kern_init(void) {
/* edata/end 不是变量，而是 kernel.ld 用 PROVIDE 定义的位置符号（实测都是 0x80203008）。 */
    extern char edata[], end[];
/* 清 [edata,end) 就是“清 .bss”；本阶段没有未初始化数据，长度实际为 0。 */
    memset(edata, 0, end - edata);

/* THU.CST 是 ucore 原版留下的实验室标识，不是本组加的。 */
    const char *message = "(THU.CST) os is loading ...\n";
/* 打印链路：cprintf→vcprintf→vprintfmt→cputch→cons_putc→sbi_console_putchar→ecall。 */
    cprintf("%s\n\n", message);
/* 死循环；编译后是自跳转 0x8020003a: j 0x8020003a，没有可返回的调用者。 */
   while (1)
        ;
}
