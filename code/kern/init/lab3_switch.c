#include <defs.h>
#include <lab3_switch.h>
#include <memlayout.h>
#include <mmu.h>
#include <pmm.h>
#include <riscv.h>
#include <sbi.h>
#include <stdio.h>
#include <string.h>
#include <trap.h>

#ifdef LAB3_CHALLENGE_SWITCH

//lab3 challenge1 2412090

/* Challenge 1：S 模式 -> U 模式 -> S 模式的完整往返。
 *
 * 设计要点：
 *   1. 用户地址空间使用一份独立的 Sv39 根页表，只额外增加 VA 0x1000
 *      （用户代码页）和 VA 0x2000/0x3000（用户栈）两条 U 权限映射；
 *      内核高半区映射从启动页表原样复制，保证切换 satp 后内核仍可执行。
 *   2. 进入 U 模式前把 sstatus.SPP 清 0，并用 sret 完成特权级下降。
 *   3. 用户代码执行 ecall，scause=8（U-mode ecall）。trap 处理函数把
 *      sepc 改成内核恢复函数、把 trapframe 里的 sp 换回内核栈，并把
 *      sstatus.SPP 置 1，于是同一条 sret 返回路径回到 S 模式。
 *   4. 恢复函数把 satp 切回启动页表并刷新 TLB，打印往返证据后关机。
 *
 * 注意：本文件只在 -DLAB3_CHALLENGE_SWITCH 时参与构建，默认评分路径
 *       （make grade）完全不受影响。
 */

#define USER_CODE_VA   0x1000UL
#define USER_STACK_VA  0x2000UL
#define USER_STACK_TOP 0x4000UL

#ifndef SSTATUS_SUM
#define SSTATUS_SUM 0x00040000UL
#endif

int lab3_switch_active = 0;

static uintptr_t saved_kernel_sp;
uintptr_t kernel_satp;

static uintptr_t user_root[SV39_NENTRY] __attribute__((aligned(PGSIZE)));
static uintptr_t user_l1[SV39_NENTRY] __attribute__((aligned(PGSIZE)));
static uintptr_t user_l0[SV39_NENTRY] __attribute__((aligned(PGSIZE)));
static uint8_t user_code[PGSIZE] __attribute__((aligned(PGSIZE)));
static uint8_t user_stack[2 * PGSIZE] __attribute__((aligned(PGSIZE)));
/* 返回 S 模式后使用的挑战专用内核栈：不信任用户栈上的任何指针。 */
uint8_t switch_stack[2 * PGSIZE] __attribute__((aligned(PGSIZE)));

extern char boot_page_table_sv39[];

static uintptr_t pte_table(uintptr_t pa) {
    return ((pa >> PGSHIFT) << 10) | PTE_V;
}

static uintptr_t pte_leaf(uintptr_t pa, uintptr_t flags) {
    return ((pa >> PGSHIFT) << 10) | flags;
}

static void build_user_address_space(void) {
    uintptr_t *boot_root = (uintptr_t *)boot_page_table_sv39;

    memset(user_root, 0, sizeof(user_root));
    memset(user_l1, 0, sizeof(user_l1));
    memset(user_l0, 0, sizeof(user_l0));

    /* 内核高半区：直接复用启动页表的 1 GiB 叶子项，保证切换 satp 后
     * __alltraps、trap()、内核栈仍然可访问。 */
    user_root[SV39_VPN2(KERNBASE)] = boot_root[SV39_VPN2(KERNBASE)];
    /* 启动期的低地址恒等映射也一并保留，避免调试路径踩空。 */
    user_root[SV39_VPN2(DRAM_BASE)] = boot_root[SV39_VPN2(DRAM_BASE)];

    /* VA 0x0000_0000 起的三级页表链。 */
    user_root[SV39_VPN2(USER_CODE_VA)] = pte_table(PADDR(user_l1));
    user_l1[SV39_VPN1(USER_CODE_VA)] = pte_table(PADDR(user_l0));

    /* 代码页：U + R/W/X + A/D；栈页：U + R/W + A/D。 */
    user_l0[SV39_VPN0(USER_CODE_VA)] =
        pte_leaf(PADDR(user_code), PTE_V | PTE_R | PTE_W | PTE_X | PTE_U | PTE_A | PTE_D);
    user_l0[SV39_VPN0(USER_STACK_VA)] =
        pte_leaf(PADDR(user_stack), PTE_V | PTE_R | PTE_W | PTE_U | PTE_A | PTE_D);
    user_l0[SV39_VPN0(USER_STACK_VA + PGSIZE)] =
        pte_leaf(PADDR(user_stack + PGSIZE),
                 PTE_V | PTE_R | PTE_W | PTE_U | PTE_A | PTE_D);
}

static void fill_user_code(void) {
    uint32_t *code = (uint32_t *)user_code;

    memset(user_code, 0, sizeof(user_code));
    code[0] = 0x05500513; /* addi a0, x0, 0x55 */
    code[1] = 0x00000073; /* ecall            */
    code[2] = 0x0000006f; /* j .              */
}

void __attribute__((noreturn, used)) lab3_switch_after_c(void) {
    cprintf("[Challenge 1] back to S-mode, satp restored to kernel page table\n");
    cprintf("[Challenge 1] PASS: S -> U -> S round trip completed\n");
    sbi_shutdown();
    for (;;) {
        asm volatile("wfi");
    }
}

/* 从 U 模式返回 S 模式后的第一条指令：先建立可信内核栈，再切回内核页表。
 * 这里用 naked 函数，保证在设置 sp 之前不访问任何内存。 */
static void __attribute__((naked, noreturn)) lab3_switch_after(void) {
    asm volatile(
        "la sp, switch_stack\n"
        "li t0, 8192\n"
        "add sp, sp, t0\n"
        /* 先切到可信内核栈，再关闭 SUM；否则 RESTORE_ALL 读不到用户栈上的 trapframe。 */
        "li t0, 0x40000\n"
        "csrc sstatus, t0\n"
        "la t0, kernel_satp\n"
        "ld t0, 0(t0)\n"
        "csrw satp, t0\n"
        "sfence.vma\n"
        "j lab3_switch_after_c\n");
}

void lab3_switch_back(struct trapframe *tf) {
    lab3_switch_active = 0;

    cprintf("[Challenge 1] user ecall: scause=0x%lx, a0=0x%lx\n",
            tf->cause, tf->gpr.a0);

    /* 同一条 sret 返回路径，改回挑战专用内核栈并返回 S 模式。
     * 这里不沿用用户栈上的 sp，避免把用户可控的指针带回内核。 */
    tf->gpr.sp = (uintptr_t)switch_stack + sizeof(switch_stack) - 16;
    tf->status |= SSTATUS_SPP;
    tf->status &= ~SSTATUS_SPIE;
    tf->epc = (uintptr_t)lab3_switch_after;
}

void lab3_switch_test(void) {
    uintptr_t sstatus;
    uintptr_t user_satp;

    build_user_address_space();
    fill_user_code();

    kernel_satp = (8UL << 60) | (PADDR(boot_page_table_sv39) >> PGSHIFT);
    user_satp = (8UL << 60) | (PADDR(user_root) >> PGSHIFT);

    asm volatile("mv %0, sp" : "=r"(saved_kernel_sp));

    /* S 模式要读写放在用户栈上的 trapframe，必须打开 SUM。 */
    sstatus = read_csr(sstatus);
    sstatus &= ~SSTATUS_SPP;
    sstatus &= ~SSTATUS_SPIE;
    sstatus &= ~SSTATUS_SIE;
    sstatus |= SSTATUS_SUM;

    lab3_switch_active = 1;

    cprintf("[Challenge 1] user address space: code=0x%lx, stack=0x%lx\n",
            (uintptr_t)USER_CODE_VA, (uintptr_t)USER_STACK_TOP);
    cprintf("[Challenge 1] switch satp and enter U-mode (sepc=0x%lx)\n",
            (uintptr_t)USER_CODE_VA);

    write_csr(satp, user_satp);
    asm volatile("sfence.vma" ::: "memory");

    asm volatile(
        "mv sp, %0\n"
        "csrw sepc, %1\n"
        "csrw sstatus, %2\n"
        "sret\n"
        :
        : "r"((uintptr_t)USER_STACK_TOP), "r"((uintptr_t)USER_CODE_VA), "r"(sstatus)
        : "memory");

    __builtin_unreachable();
}

#endif /* LAB3_CHALLENGE_SWITCH */
