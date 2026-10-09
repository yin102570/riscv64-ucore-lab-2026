/* 链接脚本：决定各段的地址与顺序。它直接决定了入口地址、bootstack 地址与 edata/end 的取值。 */
/* Simple linker script for the ucore kernel.
   See the GNU ld 'info' manual ("info ld") to learn the syntax. */

/* 目标体系结构：riscv。 */
OUTPUT_ARCH(riscv)
/* ENTRY 决定 ELF 的入口 e_entry = 0x80200000，也就是 OpenSBI 打印的 Domain0 Next Address。 */
ENTRY(kern_entry)

/* 基址 = DRAM 起始 0x80000000 + 2MiB（最前面 2MiB 留给 OpenSBI 固件）。 */
BASE_ADDRESS = 0x80200000;

SECTIONS
{
/* “.” 是定位计数器，表示当前地址；从 BASE_ADDRESS 开始向下排布。 */
    /* Load the kernel at this address: "." means the current address */
    . = BASE_ADDRESS;

/* 代码段。★ 入口能落在 0x80200000 靠的是 entry.o 被排在最前
   （entry.S 用的是普通 .text，并没有 .text.kern_entry 这个节）。 */
    .text : {
        *(.text.kern_entry .text .stub .text.* .gnu.linkonce.t.*)
    }

/* PROVIDE 只在“该符号被引用且未被定义”时才真正定义：etext 无人引用，
   所以最终符号表里看不到它（而下面被 init.c 引用的 edata/end 存在）。 */
    PROVIDE(etext = .); /* Define the 'etext' symbol to this value */

/* 只读数据（字符串常量等）；实测 624 字节，紧接 .text 之后。 */
    .rodata : {
        *(.rodata .rodata.* .gnu.linkonce.r.*)
    }

/* 把 .data 对齐到 4KB 页边界，便于将来按页管理（实测 .data 从 0x80201000 开始）。 */
    /* Adjust the address for the data segment to the next page */
    . = ALIGN(0x1000);

    /* The data segment */
/* 已初始化数据；其中 8192 字节是 entry.S 用 .space 预留的内核栈。 */
    .data : {
        *(.data)
        *(.data.*)
    }

/* 小数据节：实测仅 8 字节，内容就是 sbi.c 里的 SBI_CONSOLE_PUTCHAR（值为 1）。 */
    .sdata : {
        *(.sdata)
        *(.sdata.*)
    }

/* edata：已初始化数据的结束位置。init.c 引用它，因此会出现在符号表里。 */
    PROVIDE(edata = .);

/* 未初始化数据段。语义上初值为 0 且不占文件空间，需内核启动后自己清零；
   本阶段没有任何未初始化数据，故为空 —— 这也是 edata 与 end 相等的直接原因。 */
    .bss : {
        *(.bss)
        *(.bss.*)
        *(.sbss*)
    }

/* end：整个镜像的结束位置，与 edata 一起构成 init.c 的清零区间 [edata, end)。 */
    PROVIDE(end = .);

/* 丢弃 .eh_frame（C++ 异常展开表，裸内核用不到）与 .note.GNU-stack 注释节。 */
    /DISCARD/ : {
        *(.eh_frame .note.GNU-stack)
    }
}
