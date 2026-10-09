# entry.S —— 内核入口。kernel.ld 的 ENTRY(kern_entry) 指的就是它，加载地址 0x80200000。
# 后缀 .S 会先过 C 预处理器，所以能用下面两个头文件里的宏。
#include <mmu.h>
#include <memlayout.h>

# .text 段：a=可分配、x=可执行；%progbits 表示段内有实际数据。
    .section .text,"ax",%progbits
# 只有全局符号才能被链接器看到，也才能成为 ELF 的入口。
    .globl kern_entry
kern_entry:
# 设内核栈顶：-mcmodel=medany 把 la 展开为 auipc+addi（PC 相对）；栈向低地址增长。
    la sp, bootstacktop

# tail = 跳转但不写 ra（kern_init 是 noreturn，不需要返回）；实测编译成 2 字节 c.j。
    tail kern_init

# 内核栈放 .data：栈会被读写，必须真的占用镜像空间（.bss 只占地址不占文件）。
.section .data
# 按 2^PGSHIFT = 4KB 页对齐；下一行原注释 “# .align 2^12” 就是它的文字解释。
    # .align 2^12
    .align PGSHIFT
# bootstack=栈底、bootstacktop=栈顶，相差 KSTACKSIZE = 2 页 = 8192 字节。
    .global bootstack
# 实测链接后 bootstack=0x80201000、bootstacktop=0x80203000。
bootstack:
    .space KSTACKSIZE
    .global bootstacktop
bootstacktop: