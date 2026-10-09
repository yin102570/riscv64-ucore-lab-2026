/* console.h —— 控制台接口声明（实现见 console.c）；本阶段只有 cons_putc 真正被用到。 */
#ifndef __KERN_DRIVER_CONSOLE_H__
#define __KERN_DRIVER_CONSOLE_H__

/* 空实现：串口已由 OpenSBI 初始化好。 */
void cons_init(void);
/* 唯一被使用的接口：把字符交给 SBI 输出。 */
void cons_putc(int c);
/* 约定“暂无输入时返回 0”，所以 0 不能同时表示读到了字符 0。 */
int cons_getc(void);
/* 串口/键盘中断入口：空实现，本阶段输入靠轮询而非中断。 */
void serial_intr(void);
void kbd_intr(void);

#endif /* !__KERN_DRIVER_CONSOLE_H__ */

