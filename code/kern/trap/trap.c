#include <assert.h>
#include <clock.h>
#include <console.h>
#include <defs.h>
#include <error.h>
#include <kdebug.h>
#include <memlayout.h>
#include <mmu.h>
#include <proc.h>
#include <riscv.h>
#include <sbi.h>
#include <sched.h>
#include <stdio.h>
#include <syscall.h>
#include <trap.h>
#include <vmm.h>

#define TICK_NUM 100

/* In grading builds the kernel stops itself after a bounded number of
 * ticks.  Lab5 user programs need more than the one second that a literal
 * "100 ticks" would give, so the window is deliberately wider. */
#ifndef SHUTDOWN_AFTER
#define SHUTDOWN_AFTER 1000
#endif

static void
print_ticks(void)
{
    cprintf("%d ticks\n", TICK_NUM);
#ifdef DEBUG_GRADE
    cprintf("End of Test.\n");
    panic("EOT: kernel seems ok.");
#endif
}

void
idt_init(void)
{
    extern void __alltraps(void);
    /* 0 means "the next trap comes from the kernel"; the user path puts
     * the kernel stack top here when it returns. */
    write_csr(sscratch, 0);
    write_csr(stvec, &__alltraps);
    /* Let S-mode code copy through user mappings (sys_wait's store, exec
     * image validation); U-mode still cannot touch S-mode pages. */
    set_csr(sstatus, SSTATUS_SUM);
}

void
print_trapframe(struct trapframe *tf)
{
    cprintf("trapframe at %p\n", tf);
    print_regs(&tf->gpr);
    cprintf("  status   0x%016lx\n", tf->status);
    cprintf("  epc      0x%016lx\n", tf->epc);
    cprintf("  badvaddr 0x%016lx\n", tf->badvaddr);
    cprintf("  cause    0x%016lx\n", tf->cause);
}

void
print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%016lx\n", gpr->zero);
    cprintf("  ra       0x%016lx\n", gpr->ra);
    cprintf("  sp       0x%016lx\n", gpr->sp);
    cprintf("  gp       0x%016lx\n", gpr->gp);
    cprintf("  tp       0x%016lx\n", gpr->tp);
    cprintf("  t0       0x%016lx\n", gpr->t0);
    cprintf("  t1       0x%016lx\n", gpr->t1);
    cprintf("  t2       0x%016lx\n", gpr->t2);
    cprintf("  s0       0x%016lx\n", gpr->s0);
    cprintf("  s1       0x%016lx\n", gpr->s1);
    cprintf("  a0       0x%016lx\n", gpr->a0);
    cprintf("  a1       0x%016lx\n", gpr->a1);
    cprintf("  a2       0x%016lx\n", gpr->a2);
    cprintf("  a3       0x%016lx\n", gpr->a3);
    cprintf("  a4       0x%016lx\n", gpr->a4);
    cprintf("  a5       0x%016lx\n", gpr->a5);
    cprintf("  a6       0x%016lx\n", gpr->a6);
    cprintf("  a7       0x%016lx\n", gpr->a7);
    cprintf("  s2       0x%016lx\n", gpr->s2);
    cprintf("  s3       0x%016lx\n", gpr->s3);
    cprintf("  s4       0x%016lx\n", gpr->s4);
    cprintf("  s5       0x%016lx\n", gpr->s5);
    cprintf("  s6       0x%016lx\n", gpr->s6);
    cprintf("  s7       0x%016lx\n", gpr->s7);
    cprintf("  s8       0x%016lx\n", gpr->s8);
    cprintf("  s9       0x%016lx\n", gpr->s9);
    cprintf("  s10      0x%016lx\n", gpr->s10);
    cprintf("  s11      0x%016lx\n", gpr->s11);
    cprintf("  t3       0x%016lx\n", gpr->t3);
    cprintf("  t4       0x%016lx\n", gpr->t4);
    cprintf("  t5       0x%016lx\n", gpr->t5);
    cprintf("  t6       0x%016lx\n", gpr->t6);
}

/* scause's top bit separates asynchronous interrupts from exceptions. */
#define INTERRUPT_CAUSE_MASK (~((uintptr_t)1 << 63))

bool
trap_in_kernel(struct trapframe *tf)
{
    return (tf->status & SSTATUS_SPP) != 0;
}

/* The low two bits of an instruction decide whether it is compressed. */
static uintptr_t
instruction_length(uintptr_t epc)
{
    uint16_t insn = *(volatile uint16_t *)epc;
    return (insn & 0x3) == 0x3 ? 4 : 2;
}

void
interrupt_handler(struct trapframe *tf)
{
    switch (tf->cause & INTERRUPT_CAUSE_MASK) {
    case IRQ_S_SOFT:
        cprintf("Supervisor software interrupt\n");
        break;
    case IRQ_S_TIMER:
        clock_set_next_event();
        ticks++;
        if (ticks % TICK_NUM == 0) {
            print_ticks();
        }
        /* The timer is the only preemption source in lab5: it does not
         * switch here, it leaves a request for the trap epilogue. */
        current->need_resched = 1;
        if (ticks >= SHUTDOWN_AFTER) {
            sbi_shutdown();
        }
        break;
    case IRQ_S_EXT:
        cprintf("Supervisor external interrupt\n");
        break;
    default:
        cprintf("Unknown interrupt: cause %d\n",
                (int)(tf->cause & INTERRUPT_CAUSE_MASK));
        break;
    }
}

//LAB5 功能模块一 2410665
static void
do_page_fault(struct trapframe *tf)
{
    uint32_t error_code = (tf->cause == CAUSE_STORE_PAGE_FAULT) ? 1 : 0;

    if (trap_in_kernel(tf)) {
        print_trapframe(tf);
        panic("page fault in kernel at 0x%016lx", tf->badvaddr);
    }

    if (current->mm == NULL ||
        do_pgfault(current->mm, error_code, tf->badvaddr) != 0) {
        cprintf("pid %d: bad memory access at 0x%016lx (cause %d), killed.\n",
                current->pid, tf->badvaddr, (int)tf->cause);
        do_exit(-E_FAULT);
    }
}

//LAB5 功能模块一 2410665
void
exception_handler(struct trapframe *tf)
{
    switch (tf->cause) {
    case CAUSE_BREAKPOINT:
        cprintf("Breakpoint at 0x%016lx\n", tf->epc);
        tf->epc += instruction_length(tf->epc);
        break;
    case CAUSE_ILLEGAL_INSTRUCTION:
        cprintf("Illegal instruction at 0x%016lx\n", tf->epc);
        tf->epc += instruction_length(tf->epc);
        break;
    case CAUSE_USER_ECALL:
        /* Return to the instruction after ecall, not to ecall itself. */
        tf->epc += 4;
        syscall();
        break;

    case CAUSE_FETCH_PAGE_FAULT:
    case CAUSE_LOAD_PAGE_FAULT:
    case CAUSE_STORE_PAGE_FAULT:
        do_page_fault(tf);
        break;
    default:
        print_trapframe(tf);
        if (!trap_in_kernel(tf)) {
            do_exit(-E_FAULT);
        }
        break;
    }
}

/*
 * trap - the C half of __alltraps.
 *
 * current->tf must describe the frame we are handling: syscall() reads
 * a0..a5 from it and kernel_execve rewrites it into a user frame.  A trap
 * that returns to S-mode restores the previous pointer; a trap that
 * returns to U-mode keeps the frame that RESTORE_ALL is about to load.
 */
//LAB5 功能模块一 2410665
void
trap(struct trapframe *tf)
{
    struct trapframe *saved = current->tf;
    current->tf = tf;

    if ((intptr_t)tf->cause < 0) {
        interrupt_handler(tf);
    } else {
        exception_handler(tf);
    }

    if (trap_in_kernel(tf)) {
        current->tf = saved;
        return;
    }

    /* A killed process must not be scheduled again: handle exit first. */
    if (current->flags & PF_EXITING) {
        do_exit(-E_KILLED);
    }
    if (current->need_resched) {
        schedule();
    }
}
