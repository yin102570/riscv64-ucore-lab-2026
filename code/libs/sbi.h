/* sbi.h —— SBI 服务接口声明：内核用 ecall 陷入固件请求服务。
   下面 7 个函数中，sbi.c 只实现了 3 个（sbi_console_putchar、sbi_set_timer，及共用的 sbi_call）。 */
#ifndef _ASM_RISCV_SBI_H
#define _ASM_RISCV_SBI_H

/* 描述一段物理内存：起始地址 / 字节数 / NUMA 节点号。 */
typedef struct {
  unsigned long base;
  unsigned long size;
  unsigned long node_id;
} memory_block_info;

/* ⚠ 以下 5 个只有声明、没有实现；不被调用时不会有任何问题，调用即链接失败。 */
unsigned long sbi_query_memory(unsigned long id, memory_block_info *p);

/* 已实现：设定下一次时钟中断的时刻（后续实验做时间片调度的基础）。 */
void sbi_set_timer(unsigned long long stime_value);
void sbi_send_ipi(unsigned long hart_id);
unsigned long sbi_clear_ipi(void);
void sbi_shutdown(void);

/* 已实现：本阶段唯一实际使用的 SBI 服务（内核打印的最后一跳）。 */
void sbi_console_putchar(unsigned char ch);
/* ⚠ 未实现，但 kern/driver/console.c 的 cons_getc() 已经调用了它。 */
int sbi_console_getchar(void);

#endif
