#include <mmu.h>
#include <memlayout.h>

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
    sd a0, 0(t0)
    la t0, boot_dtb
    sd a1, 0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
    addi t0, t0, %lo(kern_init)
    jr t0

.section .data
    # .align 2^12
    .align PGSHIFT
    .global bootstack
bootstack:
    .space KSTACKSIZE
    .global bootstacktop
bootstacktop:

.section .data
    # 由于我们要把这个页表放到一个页里面，因此必须 12 位对齐
    .align PGSHIFT
    .global boot_page_table_sv39
# 分配 4KiB 内存给预设的三级页表
boot_page_table_sv39:
    # 0xffffffff_c0000000 map to 0x80000000 (1G)
    # ---- 框架原有注释：按实验要求原样保留，不删、不改 ----
    #   前 511 个页表项均设置为 0 ，因此 V=0 ，意味着是空的(unmapped)
    #   设置最后一个页表项，PPN=0x80000，标志位 VRWXAD 均为 1
    #   （框架代码即：先 .zero 8 * 511，再 .quad (0x80000 << 10) | 0xcf）
    #
    # ---- 本实验的改动：#lab2 entry.S 2410665 ----
    # 只映射高半区在本机（QEMU 7.0 + OpenSBI fw_dynamic）跑不通：csrw satp 生效后，
    # CPU 紧接着取的几条指令 PC 仍然是低地址（GDB 实测 0x8020_0038），第 2 次取指就
    # instruction page fault（cause=0xC），内核活不过 3 行。因此在项 2 补一条“启动期
    # 专用”的低地址恒等映射；项 511 的 PPN 与 VRWXAD 与框架完全一致。
    # 详见报告 §3.1.1 与「启动期低地址恒等映射」一节。
    # 项 0、项 1：V=0（未映射）
    .zero 8 * 2
    # 项 2：低 1 GiB 恒等映射（本实验新增，启动期专用）
    .quad (0x80000 << 10) | 0xcf # VRWXAD
    # 项 3 ~ 项 510：V=0（未映射）
    .zero 8 * 508
    # 项 511：高半区 1 GiB 映射（框架原意）
    .quad (0x80000 << 10) | 0xcf # VRWXAD

    .global boot_hartid
boot_hartid:
    .quad 0
    .global boot_dtb
boot_dtb:
    .quad 0
