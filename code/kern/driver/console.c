/* console.c —— 内核打印链路的最后一环，真正的输出由 OpenSBI 完成。 */
/* ⚠ cons_getc() 调用的 sbi_console_getchar() 在 sbi.c 里并未实现，只因无人调用它、
   且 --gc-sections 会丢弃未引用的节，现在才没报链接错误；一旦真被调用就会 undefined reference。 */
#include <sbi.h>
#include <console.h>

/* kbd_intr/serial_intr：空实现（没有中断系统，属后续实验的骨架）。 */
/* kbd_intr - try to feed input characters from keyboard */
void kbd_intr(void) {}

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init：空实现，无需重复配置串口硬件。 */
/* cons_init - initializes the console devices */
void cons_init(void) {}

/* 转成 unsigned char：SBI 约定该服务只使用低 8 位。 */
/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }

/* 轮询式读取（不阻塞、不睡眠）；详情见文件头的 ⚠ 说明。 */
/* *
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
    return c;
}
