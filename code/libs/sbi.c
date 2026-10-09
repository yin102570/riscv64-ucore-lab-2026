/* sbi.c —— ecall 的最小封装。SBI 约定：功能号放 a7(x17)，参数放 a0..a2(x10..x12)，返回值在 a0。 */
// libs/sbi.c
#include <sbi.h>
#include <defs.h>


/* SBI 旧式功能号（规范固定，不可改）。写成全局变量而非宏：实测只有被引用到的
   SBI_CONSOLE_PUTCHAR(=1) 被链接进 .sdata（8 字节、值为 1），其余被 --gc-sections 丢弃。 */
uint64_t SBI_SET_TIMER = 0;
uint64_t SBI_CONSOLE_PUTCHAR = 1; 
uint64_t SBI_CONSOLE_GETCHAR = 2;
uint64_t SBI_CLEAR_IPI = 3;
uint64_t SBI_SEND_IPI = 4;
uint64_t SBI_REMOTE_FENCE_I = 5;
uint64_t SBI_REMOTE_SFENCE_VMA = 6;
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

/* sbi_call：装寄存器 → ecall → 取 a0。sbi.h 未声明它，因函数很短，-O2 会把它内联进调用者。 */
uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
/* ecall 实测位于 0x80200492，陷入 OpenSBI 陷阱入口 0x80000408；"memory" 破坏描述阻止访存被重排。 */
    __asm__ volatile (
        "mv x17, %[sbi_type]\n"
        "mv x10, %[arg0]\n"
        "mv x11, %[arg1]\n"
        "mv x12, %[arg2]\n"
        "ecall\n"
        "mv %[ret_val], x10"
        : [ret_val] "=r" (ret_val)
        : [sbi_type] "r" (sbi_type), [arg0] "r" (arg0), [arg1] "r" (arg1), [arg2] "r" (arg2)
        : "memory"
    );
/* 返回固件写入 a0 的值。 */
    return ret_val;
}

/* 内核唯一的输出通道，打印链路到此结束。 */
void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}

/* 为后续时钟中断预留的实现，本阶段尚未使用。 */
void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
/* sbi.h 里另外 5 个函数（query_memory / send_ipi / clear_ipi / shutdown / console_getchar）
   在本文件中都没有实现；补全时照上面的模式调用 sbi_call(功能号, 参数...) 即可。 */
}
