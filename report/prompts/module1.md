# 模块一：用户态系统调用

负责人：2410665 殷佳仪

## 1. 问题边界

模块一只解决一件事：用户程序执行 `ecall` 之后，内核怎样可靠地拿到调用号和参数、完成服务，再回到用户态。它不创建进程，也不复制地址空间；进程生命周期的语义留给模块二到模块四。

这条链路上有三个互相独立的现场：

1. 硬件现场：`sepc`、`sstatus`、`scause`、`stval`。
2. 软件现场：`struct trapframe` 中保存的 32 个通用寄存器和 4 个 CSR 快照。
3. 调度现场：`struct context`，只保存 `ra/sp/s0-s11`。

模块一必须保证前两者一致。调度现场不属于这里，把 `a0..a7` 塞进 `context` 会把“异常返回”和“线程切换”混成同一件事。

## 2. Spec

### 2.1 系统调用 ABI

| 寄存器 | 进入内核时 | 返回用户态时 |
|---|---|---|
| `a0` | 系统调用号 | 返回值，负数表示 `-errno` |
| `a1..a5` | 参数 1..5 | 不保证 |
| `sp` | 用户栈指针 | 必须原样恢复 |
| `sepc` | `ecall` 指令地址 | 必须指向 `ecall` 的下一条指令 |

不变量：

- `a0` 越界或表项为空时返回 `-E_INVAL`，不能跳转到空指针。
- 用户态传入的指针必须先经 `user_mem_check()`，检查范围、VMA 权限和栈 guard page。
- `sys_wait` 的 `store` 是写操作，必须按 `VM_WRITE` 检查；只读页不能作为退出码落点。
- `sys_exec` 只从用户态进入：name 和 binary 都按用户 VMA 检查。`kernel_execve` 不经过 `sys_exec`，它直接调用 `do_execve`，指针指向内核镜像。
- `sys_pgdir` 输出的是当前进程的页表，不是 boot 页表。

### 2.2 陷阱入口与返回

`SAVE_ALL` 必须同时支持两个方向：

- U→S：`sscratch` 保存内核栈顶，`sp` 是用户栈，交换后在内核栈上建帧。
- S→S：`sscratch` 为 0，交换后 `sp` 为 0，必须从 `sscratch` 取回原内核 `sp`。

`RESTORE_ALL` 按保存的 `sstatus.SPP` 判断返回方向。返回用户态时，把“本帧之上的内核栈顶”写回 `sscratch`，再恢复通用寄存器，最后恢复 `sp` 并 `sret`。`sp` 必须最后恢复，否则后续 `LOAD` 会读到用户栈。

`sepc` 的推进只发生在 `ecall` 分支。定时器中断和页故障不能加 4，否则会跳过一条真实指令。

## 3. 最终提示词

```text
你在 ucore lab5 的 RISC-V 代码上实现系统调用入口，只修改
kern/trap/trapentry.S、kern/trap/trap.c、kern/syscall/syscall.c、
kern/syscall/syscall.h、libs/unistd.h，以及必要的 mm 辅助函数。

约束：
1. 不重写整个陷阱框架。保留现有 __alltraps/__trapret 符号和
   struct trapframe 的 36 槽布局，forkrets 仍按 a0 恢复 sp。
2. SAVE_ALL 必须区分 U→S 与 S→S。用 csrrw sp, sscratch, sp，
   若交换后 sp 为 0，说明来自内核态，再从 sscratch 取回原 sp。
3. RESTORE_ALL 只在返回用户态时把内核栈顶写回 sscratch；sp 最后恢复。
4. exception_handler 只处理 CAUSE_USER_ECALL，进入后 epc 加 4；
   其它异常不能推进 epc。断点和非法指令按指令长度处理。
5. syscall() 从 current->tf 读 a0 号、a1..a5 参数，表驱动分发，
   越界和空表项返回 -E_INVAL，结果写回 a0。
6. 实现 SYS_exit/fork/wait/exec/yield/kill/getpid/putc/pgdir 九个调用。
   sys_wait 的 store 按写权限检查；sys_exec 只接受用户态调用，
   name 和 binary 都要通过 user_mem_check；sys_pgdir 遍历 current->pgdir。
7. 不修改 do_fork/do_exit/do_wait 的语义，它们由其他模块负责。
```

## 4. 迭代与 bug

### 4.1 `lock_t` 的宽度

第一版沿用了 `volatile bool`。RISC-V 的 `amo*.d` 按 32 位原子操作，编译器对 `bool` 只分配 1 字节，原子写会踩到相邻字段。现象不是立刻崩溃，而是别的锁状态偶发变化。改成 `volatile uint_t` 后，锁对象与原子指令宽度一致。

### 4.2 内核态陷阱把栈帧建到地址 0

最初 `SAVE_ALL` 只写了 `csrrw sp, sscratch, sp`。用户态进来时正确，内核态陷阱进来时 `sscratch` 为 0，交换后 `sp` 变成 0，随后 `addi sp, sp, -36*8` 访问非法地址。修复是交换后判断 `sp` 是否为 0，为零则从 `sscratch` 取回原内核 `sp`，并在保存完通用寄存器后清空 `sscratch`，让嵌套陷阱走内核分支。这条分支后来被内核定时器和页故障实际用到。

### 4.3 `epc` 被重复推进

早期把 `tf->epc += 4` 写在 `exception_handler()` 的公共出口。定时器中断和页故障也走这个出口，返回后随机跳过一条指令，表现为用户程序莫名其妙地跑飞。后来只在 `CAUSE_USER_ECALL` 分支推进，且 `CAUSE_BREAKPOINT`/`CAUSE_ILLEGAL_INSTRUCTION` 用指令长度判断压缩指令。

### 4.4 `current->tf` 的时序

`syscall()` 读 `current->tf`，而 `trap()` 如果在调用 `exception_handler()` 之后才赋值，`syscall()` 读到的是上一次的旧帧，参数和返回值全部错位。现在的顺序是进入 `trap()` 先保存 `saved`、立刻 `current->tf = tf`，再分发；返回内核态时恢复 `saved`，返回用户态时保留本帧。

### 4.5 用户指针没有检查

`sys_wait` 最初直接 `*code_store = exit_code`。用户传一个内核地址或未映射地址，内核态写触发页故障，`do_page_fault` 直接 panic。修复是先用 `user_mem_check(current->mm, store, sizeof(int), 1)` 检查写权限；`sys_exec` 对 name 和 binary 都做读检查，并且明确只服务用户态调用。

### 4.6 `sys_pgdir` 看错了页表

第一版直接遍历 `boot_pgdir_va`，输出永远只有内核映射，用户程序看不到自己的段。`pgdir` 测试虽然能打印，但语义是错的。改成 `print_pgdir((pde_t *)KADDR(current->pgdir))`，由调用者传入当前进程的页表根。

### 4.7 `__alltraps` 没有 4 字节对齐

用户程序第一次 `ecall` 后，串口重新打印 `DTB Init`，第一反应是 QEMU 复位。用 `-d int` 只看到一次 `user_ecall`，后面紧跟内核地址上的 `load_page_fault`；再对 `objdump` 才发现 `__alltraps` 在 `...0d42`。`stvec` 的低两位是模式位，`10` 是保留值，CPU 不会跳到我们以为的入口。加 `.align 2` 后恢复正常。这个 bug 提醒我们：汇编入口的地址约束不是“最好满足”，而是 ABI 的一部分。

## 5. 静态自查清单

- `SAVE_ALL` 的 36 个槽位与 `struct trapframe` 的字段顺序逐项对应。
- `RESTORE_ALL` 中 `sp` 是最后一个 `LOAD`。
- 返回用户态前 `sscratch` 等于本帧之上的内核栈顶。
- `sstatus.SPP` 在 `load_icode` 中被清零，`SPIE` 被置 1，`SIE` 被清零。
- 系统调用号小于 `NR_SYSCALLS`，表项非空。
- `sys_wait` 的 store 为 NULL 或通过写检查。
- `sys_exec` 只接受用户态指针，name 和 binary 都通过读检查。
- `__alltraps` 4 字节对齐，`stvec` 低两位为 0。
