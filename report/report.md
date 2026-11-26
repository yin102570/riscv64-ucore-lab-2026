# 操作系统实验报告 · Lab 5：用户程序

## 实验基本信息

| 项目 | 内容 |
|---|---|
| 实验名称 | Lab 5：用户程序 |
| 交付代码 | `lab5/code` |
| 运行环境 | WSL2 Ubuntu 22.04、riscv64-unknown-elf 交叉工具链、qemu-system-riscv64 7.0.0、OpenSBI `fw_dynamic`、gdb-multiarch |
| 小组成员 | 2410665 殷佳仪（组长）、2410749 宋秋实、2412090 兰雨杉 |

## 一、实验目的

1. 理解 U 态与 S 态之间的唯一合法入口：`ecall` 进入陷阱、`sret` 返回，以及 `sstatus`、`sepc`、`sscratch` 三个 CSR 在其中的作用。
2. 掌握系统调用的寄存器 ABI、表驱动分发和用户指针检查，理解“内核不能相信用户传来的任何地址”。
3. 掌握第一个用户进程的构造过程：内核线程 → `kernel_execve` → `load_icode` → 伪造陷阱返回 → 用户入口。
4. 掌握 `fork` 的复制语义、`exit/wait` 的生命周期和僵尸进程回收，理解进程树不变量。
5. 理解 COW 如何把“复制地址空间”推迟到第一次写，以及引用计数、页表权限和 TLB 三者必须同时正确。

## 二、整体逻辑

### 2.1 本章的主线

Lab2 到 Lab4 的 CPU 始终在内核态运行：内核线程自己创建、自己调度、自己退出。Lab5 要跨过一条边界：让一段普通的 C 程序在 U 态运行，并且能够请求内核服务、创建子进程、退出并被父进程回收。

这条边界由两组现场共同支撑：

- `struct trapframe` 描述“异常返回视角”的完整现场，包含 32 个通用寄存器和 `status/epc/badvaddr/cause`。它决定 `sret` 之后 CPU 在哪个特权级、从哪条指令继续。
- `struct context` 描述“调度器视角”的现场，只保存 `ra/sp/s0-s11`。它决定 `switch_to` 之后内核栈和 callee-saved 寄存器换到哪个进程。

把两者混用，是本实验最典型的错误来源：第一次启动用户进程需要伪造 `trapframe`，进程切换需要保存 `context`，而 `fork` 同时涉及两者。

### 2.2 逐步实现的顺序

我们按依赖关系分四步，而不是按文件顺序：

1. **先让系统调用能进能出**。用户程序的第一条 `ecall` 就要依赖 `SAVE_ALL/RESTORE_ALL`。如果栈切换和 `epc` 推进不正确，后面的进程创建根本走不到。模块一先建立这条最小闭环，用一个只打印字符的调用验证 U→S→U。
2. **再让第一个用户进程跑起来**。系统调用只能被已有用户进程调用；第一个用户进程必须由内核线程“扶上马”。模块二用 `kernel_thread` 构造内核线程，用 `kernel_execve` 调用 `do_execve` 换掉地址空间并改写当前 trapframe，再跳到 `forkrets/__trapret`，让 `sret` 完成特权级下降。我们试过 S 态 `ecall`，在 RISC-V 上走不通，原因见模块二。
3. **然后让进程可以复制**。有了第一个用户进程，`fork` 才有意义。模块三实现 `do_fork/copy_mm/copy_thread`，子进程从 `fork()` 返回 0，父进程得到 PID，两者拥有独立的 `proc_struct`、内核栈和地址空间。
4. **最后补齐生命周期**。`exit`、`yield`、`kill`、`wait` 让进程树可以收敛：退出者变成僵尸，父进程回收，孤儿重挂到 `initproc`。只有这条链闭合，`init_main` 的断言才可能成立。

这个顺序的合理性在于：每一步都能单独观察。系统调用看返回值，首个进程看第一条用户输出，fork 看父子 PID 和页隔离，exit/wait 看 `all user-mode processes have quit.`。如果反过来先写 `do_exit`，一旦第一次 `sret` 就失败，根本分不清是陷阱入口、页表还是生命周期的问题。

## 三、实验内容与实现

### 模块一：用户态系统调用（负责人：殷佳仪）

涉及文件：`kern/trap/trapentry.S`、`kern/trap/trap.c`、`kern/syscall/syscall.c`、`kern/syscall/syscall.h`、`libs/unistd.h`、`libs/riscv.h`。

#### 核心设计

**栈切换是双向的。** `SAVE_ALL` 用 `csrrw sp, sscratch, sp` 交换用户栈和内核栈。从 U 态进来时 `sscratch` 是内核栈顶，交换后 `sp` 非零，直接在当前内核栈上建帧；从 S 态进来时 `sscratch` 为 0，交换后 `sp` 为 0，必须从 `sscratch` 取回原内核 `sp`。这条 S→S 分支不是为 `kernel_execve` 准备的：内核里的时钟中断、缺页和非法指令都会走它。如果只写 U→S，内核自身的陷阱就会把栈帧建到地址 0。

**返回方向由 `sstatus.SPP` 决定。** `RESTORE_ALL` 读取保存的 `sstatus`，若 SPP=0（返回用户态），把“本帧之上的内核栈顶”写回 `sscratch`，保证下一次陷阱能从同一位置开始；若 SPP=1（返回内核），保持 `sscratch` 为 0。通用寄存器恢复完后最后恢复 `sp`，否则后续 `LOAD` 会读到用户栈。

**`epc` 只在 `ecall` 分支推进。** 定时器中断和页故障返回时必须重执行被打断的指令，不能加 4。断点和非法指令用指令长度判断，兼容压缩指令。

**`stvec` 的入口地址必须 4 字节对齐。** `stvec` 的低两位不是地址的一部分：00 是直接模式，01 是向量模式，10/11 保留。我们的 `__alltraps` 起初落在 `...0d42`，写进 `stvec` 后硬件把它解释成保留模式。用户态第一次 `ecall` 并没有进入陷阱，而是跳回了内核启动地址，串口上反复打印 `DTB Init`，看起来像 QEMU 复位。修复只是在 `__alltraps` 前加 `.align 2`。

**系统调用是表驱动的。** `syscall()` 从 `current->tf` 读 `a0` 号和 `a1..a5` 参数，检查调用号小于 `NR_SYSCALLS` 且表项非空，结果写回 `a0`。`current->tf` 必须在进入 `trap()` 时立刻设置，不能等 `exception_handler()` 返回后再设，否则 `syscall()` 读到上一次的旧帧。

**用户指针全部先检查。** `sys_wait` 的 `store` 按写权限检查；`sys_exec` 对 name 和 binary 都按读权限检查，并且只接受用户态调用——`kernel_execve` 不经过 `sys_exec`，而是直接调用 `do_execve`；`sys_pgdir` 遍历 `current->pgdir`，而不是 boot 页表。

完整的 spec、最终提示词和迭代记录见 [prompts/module1.md](prompts/module1.md)。

#### bug 复盘

1. `lock_t` 用 `volatile bool`，而 `amo*.d` 按 32 位原子写，越界踩到相邻字段。改成 `volatile uint_t`，让锁对象宽度与原子指令一致。
2. `SAVE_ALL` 最初只有 U→S 一条路。内核态陷阱进来时 `sscratch` 为 0，交换后 `sp=0`，随后 `addi sp, sp, -288` 访问非法地址。加 `bnez` 分支从 `sscratch` 取回原 `sp`，并在保存完通用寄存器后清空 `sscratch`，让嵌套陷阱走内核分支。
3. `tf->epc += 4` 一度写在异常处理公共出口，定时器中断也执行，返回后随机跳过指令。后来只在 `CAUSE_USER_ECALL` 分支推进。
4. `sys_wait` 直接写 `*code_store`，用户传内核地址时触发内核页故障 panic。改为先 `user_mem_check(..., 1)`。
5. `sys_pgdir` 第一版遍历 `boot_pgdir_va`，只能看到内核映射，`pgdir` 测试虽然打印但语义错误。改为 `print_pgdir((pde_t *)KADDR(current->pgdir))`。
6. `syscall.c` 的整型参数经 `va_arg(ap, uintptr_t)` 读取，但调用点传 `int`，LP64 下会拼进相邻槽。所有 `sys_*` 包装显式转 `(uintptr_t)(intptr_t)`。
7. `__alltraps` 没有 4 字节对齐，地址是 `...0d42`，`stvec` 的低两位被当成保留模式。现象是用户第一次 `ecall` 后内核重新打印 `DTB Init`；`-d int` 里只有一次 `user_ecall`，紧接着是内核地址上的 `load_page_fault`，很像复位，实际是入口地址错了。加 `.align 2` 后恢复。

### 模块二：创建并加载第一个用户进程（负责人：殷佳仪）

涉及文件：`kern/process/proc.c` 的 `alloc_proc/proc_init/kernel_thread/init_main/user_main/kernel_execve/do_execve/load_icode`、`tools/user.ld`、`user/libs/*`。

#### 核心设计

**`kernel_thread` 构造最小 trapframe。** `s0 = fn`、`s1 = arg`，与 `kernel_thread_entry` 的 `move a0, s1; jalr s0` 对应；`epc` 指向 `kernel_thread_entry`；`status` 置 `SPP|SPIE`、清 `SIE`。新线程第一次被调度时走 `switch_to → forkret → forkrets → __trapret → sret`，用陷阱返回机制把栈上的 trapframe 装回寄存器。

**`kernel_execve` 复用陷阱返回，但不经过 S 态 `ecall`。** `do_execve()` 替换地址空间并改写 `current->tf`，随后 `kernel_execve()` 直接调用 `forkrets(current->tf)`，把 `sp` 指向这个 trapframe，跳进 `__trapret`，由 `sret` 完成特权级下降。我们最初按 x86 ucore 的经验让内核线程执行一次 S 态 `ecall`，在 RISC-V 上不成立：S 态 `ecall` 进入的是 SBI（M 态），不会投递给 `stvec`。这个差异必须从平台语义上解释，不能照搬。

**`load_icode` 按 `p_memsz` 建映射，按 `p_filesz` 拷内容。** 每个段先校验 `p_filesz <= p_memsz`、文件偏移不越界、虚拟范围在 `USERBASE..USERTOP`。映射范围用 `p_memsz`，整页清零后再拷文件内容，`.bss` 自然为零。`p_memsz == 0` 的空段直接跳过，否则会生成零长度 VMA。

**用户栈是带 guard page 的可增长 VMA。** `[USTACKTOP - USTACKSIZE, USTACKTOP)` 标记 `VM_STACK`，最低一页不映射，`do_pgfault()` 在 `la < vm_start + PGSIZE` 时拒绝。靠近栈顶预映射 4 页，保证第一次压栈不需要立刻走缺页。

**`sstatus` 的三位决定第一次返回。** `SPP` 清零表示返回 U 态，`SPIE` 置 1 表示 `sret` 后开中断，`SIE` 清零表示 `sret` 之前不被中断。忘记清 `SPP` 会回到 S 态，用户入口立刻取指页故障。

完整的 spec、最终提示词和迭代记录见 [prompts/module2.md](prompts/module2.md)。

#### bug 复盘

1. 只按 `p_filesz` 映射，`.bss` 尾部没有页，`testbss` 读到上一任页主的残留数据。改为按 `p_memsz` 映射并清零。
2. 链接脚本只有 `.data` 前页对齐，`.text/.rodata` 结束在页中间时，`mm_map` 的 `ROUNDDOWN/ROUNDUP` 让相邻 VMA 重叠，`insert_vma_struct()` 断言。每个段前都加 `ALIGN(0x1000)`。
3. `p_memsz == 0` 的空段生成零长度 VMA，后续 `find_vma` 和 `exit_mmap` 行为异常。段循环同时跳过空段。
4. `kernel_execve` 第一版直接调用 `do_execve` 后正常返回，日志里 `ret = 0`，却没有任何用户输出：地址空间已经换掉，CPU 仍停在 S 态执行 `user_main`。第二版照搬 x86 思路走 S 态 `ecall`，在 RISC-V 上 ecall 被 SBI 接走，仍然回不到 `stvec`。最终改为 `do_execve` 成功后 `forkrets(current->tf)`。
5. 构造 trapframe 时忘记清 `SPP`，`sret` 回到 S 态，用户入口取指页故障。改为 `(status & ~SPP) | SPIE` 并清 `SIE`。
6. 只建栈 VMA 不预映射，第一次压栈就缺页，guard 边界容易写错。预映射栈顶 4 页，保留 `do_pgfault` 的 guard 检查。
7. `CLONE_VM` 分支只复制了 `mm`，漏了 `proc->pgdir = PADDR(oldmm->pgdir)`，共享线程第一次被调度时 `satp` 指向旧值。补上。
8. `ulib.h` 的 `assert` 用 `cprintf` 却没有包含 `stdio.h`，用户程序编译时出现隐式声明。补 `#include <stdio.h>`。
9. `init_main` 用 `kernel_thread(...) != 0` 判断失败。`do_fork` 成功时返回子进程 PID（第一次是 2），父进程第一次启动就 `panic("create user_main failed")`。改成 `<= 0`，把“返回 PID”和“返回错误码”分开。

### 模块三：复制用户进程（负责人：宋秋实）

涉及文件：`kern/process/proc.c` 的 `do_fork/copy_mm/copy_thread`、`kern/mm/vmm.c` 的 `dup_mmap`、`kern/mm/pmm.c` 的 `copy_range`。默认 fork 走 COW，`copy_range` 是关闭 COW 时的全量复制对照路径。

#### 核心设计

`do_fork()` 按七步执行，每步失败都能回滚：`alloc_proc` → `setup_kstack` → `copy_mm` → `copy_thread` → `get_pid` 后 `hash_proc/set_links` → `wakeup_proc` → 返回 pid。`get_pid` 必须在挂链表之前调用，否则会把自己当成冲突源。

`copy_mm()` 分两条路：`CLONE_VM` 只增加 `mm_count` 并共享页表；普通 `fork` 新建 `mm`、复制内核高半区、`dup_mmap()` 逐 VMA 复制。`copy_thread()` 把父进程的 trapframe 复制到子进程内核栈顶，`gpr.a0 = 0`，`gpr.sp` 保持用户栈指针，`context.ra = forkret`、`context.sp = proc->tf`。

子进程第一次被调度时，`switch_to` 的 `ret` 跳到 `forkret`，再走 `forkrets → __trapret → sret`，从 `fork()` 返回 0。父进程继续执行，返回子进程 PID。

### 模块四：退出、让出、终止与等待（负责人：兰雨杉）

涉及文件：`kern/process/proc.c` 的 `do_exit/do_yield/do_kill/do_wait`、`kern/schedule/sched.c` 的 `wakeup_proc`。

#### 核心设计

`do_exit()` 只释放进程自己能安全释放的东西：切回 boot 页表、按引用计数释放 mm、把子进程重挂到 `initproc`、置 `PROC_ZOMBIE`、记录 `exit_code`、唤醒等待的父进程。PCB 和内核栈不能自己释放，因为还要靠它们完成 `schedule()`；最终回收由父进程 `do_wait()` 的 `unhash_proc/remove_links/put_kstack/kfree` 完成。

`do_wait()` 扫描子进程链，找到僵尸就取退出码并回收；没有僵尸但还有子进程就睡眠，`wait_state = WT_CHILD`；没有符合条件的子进程返回 `-E_BAD_PROC`。被 `kill` 唤醒后检查 `PF_EXITING`，返回 `-E_KILLED`，由陷阱返回路径执行真正的 `do_exit`。

`do_yield()` 只置 `need_resched`，真正的切换留给陷阱返回前的 `schedule()`。`do_kill()` 置 `PF_EXITING`，若目标在睡眠则唤醒它，让它在下一个安全点退出。

#### bug 复盘

1. `ulib.h` 把 `wait` 声明成 `int wait(void)`，测试程序里却同时出现 `wait(&code)` 和 `wait(NULL)`，用户程序编译直接失败。统一为 `int wait(int *store)`，内部转 `sys_wait(0, store)`。
2. `forktree` 的子进程在 `tree(depth-1)` 返回后没有退出，继续执行父分支的 `assert(pid > 0)`，而它手里的 `pid` 是 `fork` 返回的 0，断言必然失败。子分支补 `exit(0)`。
3. COW 第一版只改父页表权限、没有 `tlb_invalidate`，父进程写后仍命中旧 TLB，子进程会读到旧页。页表权限、引用计数、TLB 三者必须一起更新。
4. `wakeup_proc` 对已经是 `RUNNABLE` 的进程重复唤醒会覆盖 `wait_state`，对 `ZOMBIE` 唤醒则会让调度器选中一个已退出进程。进入函数先判断这两个状态并直接返回。

### COW Challenge（负责人：兰雨杉）

`fork` 的默认路径是 COW：`cow_copy_range()` 把父进程可写页改成只读并置 `PTE_COW`，子进程共享同一物理页，引用计数加一。任一进程写这些页时触发页故障，`do_pgfault()` 检查 `PTE_COW`：若引用计数为 1，直接恢复写权限；否则分配新页、拷贝内容、重映射并刷新 TLB。

状态转换可以写成四个状态：

| 状态 | 页表项 | 引用计数 | 触发事件 | 下一状态 |
|---|---|---|---|---|
| 独占可写 | `W=1, COW=0` | 1 | `fork` | 共享只读 |
| 共享只读 | `W=0, COW=1` | 2 | 任一进程写 | 写故障 |
| 写故障、多引用 | `W=0, COW=1` | 2 | 分配新页并拷贝 | 独占可写（写者） |
| 写故障、单引用 | `W=0, COW=1` | 1 | 直接恢复 `W=1` | 独占可写 |

COW 的难点不在拷贝，而在三个一致性：页表项权限、物理页引用计数、TLB 旧翻译。漏掉 `tlb_invalidate()` 会出现“第一次写成功、第二次仍读旧页”；漏掉引用计数会在 `exit_mmap()` 时提前释放仍被共享的页。

我们另写了 `user/cowtest.c`：父进程在第一个子进程仍存活时再次 `fork`，让共享页引用计数达到 3；两个子进程分别写 `.data` 和栈页，父进程最后必须仍读到 `shared=1, local=10`。第一次运行在 `pid 4` 上报 `bad memory access at 0x803000`。根因是第二次 fork 时 `perm = (*ptep & PTE_USER)` 把软件位 `PTE_COW` 过滤掉了：父页已经是 `W=0, COW=1`，新子进程却拿到“只读但不带 COW”的页，写故障无法被 `do_pgfault()` 识别。把掩码改成 `PTE_USER | PTE_COW` 后用例通过。这个 bug 只有“连续 fork + 子进程仍存活”才会触发，`forktest` 和 `forktree` 都覆盖不到。

Dirty COW 的启示是：COW 的“检查”和“使用”之间不能有可被利用的窗口。内核必须在写故障处理中原子地确认页仍是 COW、引用计数仍大于 1，再决定拷贝；如果先把页表改成可写、再去拷贝，另一个进程就能在窗口内写到同一页。ucore 单核关中断的实现天然缩小了这个窗口，但多核下必须依赖页表锁和引用计数原子操作。

### Challenge：用户程序的预加载方式

我们的用户程序在构建时编译成 ELF，再由 `objcopy -I binary` 变成内核镜像里的二进制数组，随内核一起加载。运行时 `kernel_execve()` 选中数组，`load_icode()` 在 `kernel_execve` 的时刻才建立用户页表、拷贝各段。也就是说，程序“预先嵌入内核镜像”，但用户地址空间是“执行时按 ELF 段建立”的。

这与常用操作系统有三点不同：

1. 常用 OS 从文件系统按路径读取可执行文件；ucore 没有文件系统，程序名只是内核里的符号。
2. 常用 OS 支持按需分页，代码页在第一次访问时才从磁盘读入；ucore 在 `load_icode()` 中一次性映射并拷贝所有 `PT_LOAD` 段。
3. 常用 OS 支持动态链接和共享库；ucore 的用户程序是静态链接的独立镜像。

原因是 Lab5 的目标是验证进程创建、地址空间和系统调用，不是文件系统。把程序嵌入内核可以让测试完全可复现，不依赖外部存储；代价是内核镜像变大，程序不能在不重新编译内核的情况下替换。

### 分支任务：GDB 观察 `ecall` 与 `sret`（负责人：宋秋实）

指导书用双重 GDB 观察 QEMU 的地址翻译和陷阱注入。我们在 guest 侧用 `gdb-multiarch` 连接 `qemu-system-riscv64 -s -S`，先 `add-symbol-file obj/user/exit.out` 加载用户符号，再在内核 `syscall()` 和 `sret` 指令上下断点；QEMU 侧直接对照源码。`exit` 用例第一次进入内核时抓到的现场是：

```text
nr=30 a1=0x49 a2=0x0 epc=0x8011ac
sepc=0x8011a8 sstatus=0x8000000200046020 sscratch=0 sp=0xffffffffc041fec0
```

`a1=0x49` 是字符 `I`，`epc` 已经由 `exception_handler` 加了 4，CSR 里的 `sepc` 仍指向 `ecall`；`sstatus` 的 SPP=0、SPIE=1，说明这是从 U 态进来的。继续到 `sret` 前：

```text
sepc=0x8011ac sstatus=0x8000000200046020 sscratch=0xffffffffc0420000 sp=0x7ffffe90
```

`sscratch` 已经换成该进程内核栈顶，`sp` 回到用户栈，`sepc` 是 `ecall` 的下一条指令。完整记录在 `report/logs/runtime/gdb-ecall-sret.log`。

QEMU 侧的陷阱注入在 `target/riscv/cpu_helper.c` 的 `riscv_raise_exception()`：它按 `scause` 查 `stvec`，把当前 `sstatus.SIE` 写进 `SPIE`、清 `SIE`、把 `SPP` 置为当前特权级，再把 `sepc` 设为出错指令。`sret` 在 `target/riscv/insn_trans/trans_privileged.c.inc` 的 `trans_sret()`：按 `SPP` 选择返回模式，把 `SPIE` 写回 `SIE`，然后跳到 `sepc`。这也解释了 `load_icode` 为什么必须同时设置 `SPP/SPIE/SIE`：三个位分别控制“回到哪一层”“回去后开不开中断”“回去前是否响应中断”。

## 四、测试与验证

评测程序共 13 个，构建时通过 `TEST=<name>` 把目标用户程序嵌入内核，运行时由 `user_main()` 执行。判定标准是“本用例的 pass 标记”加“`all user-mode processes have quit.`”同时出现；三个故障用例反过来要求出现 `bad memory access`、且不出现 `failed` 行。

| 用例 | 验证点 | 判定 |
|---|---|---|
| `hello` | 第一个用户进程能进入 U 态并输出 | `hello world.` |
| `exit` | `exit` 系统调用与父进程回收 | `exit pass.` |
| `forktest` | 连续 fork、父子返回值与子进程回收 | `forktest pass.` |
| `yield` | `need_resched` 与主动让出 | `yield pass.` |
| `badarg` | 非法用户指针被拒绝 | `badarg pass.` |
| `pgdir` | `sys_pgdir` 输出当前进程页表 | `pgdir pass.` |
| `testbss` | `.bss` 清零 | `testbss pass.` |
| `waitkill` | `kill` 唤醒等待、退出码 `-E_KILLED` | `waitkill pass.` |
| `spin` | 定时器抢占与多进程轮转 | `spin pass.` |
| `forktree` | 多层进程树与孤儿重挂 | `forktree pass.` |
| `faultread` | 读未映射地址被杀死 | `bad memory access`，无 `faultread failed` |
| `faultreadkernel` | 读内核地址被杀死 | `bad memory access`，无 `faultreadkernel failed` |
| `badsegment` | 非法段访问被杀死 | `bad memory access`，无 `badsegment failed` |

构建与运行命令：

```sh
make clean
make TEST=hello
make qemu
make grade
```

我们在 WSL2 + QEMU 7.0.0 上执行 `make grade`，13 个基础用例全部通过，输出为 `Total Score: 13/13`；另加的 COW 扩展用例 `make TEST=cowtest` 输出 `cowtest pass.`。评分原始输出在 `report/logs/runtime/grade.log`，`exit` 的完整串口输出在 `report/logs/runtime/qemu-exit.log`，COW 用例输出在 `report/logs/runtime/qemu-cowtest.log`，GDB 在 `syscall` 入口和 `sret` 前抓到的寄存器现场在 `report/logs/runtime/gdb-ecall-sret.log`。报告里的数字和寄存器值都来自这些归档，没有示意值。

## 五、知识点对照

| 实验中的落点 | OS 原理中的概念 | 含义 | 关系与差异 |
|---|---|---|---|
| `ecall` + `__alltraps` + `sret` | 系统调用、陷阱、特权级切换 | 用户程序通过受控入口请求内核服务，硬件保存现场并切换特权级 | 课上把系统调用讲成“函数调用”，实验里它是两次特权级切换；`epc`、`sstatus`、`sscratch` 任何一个错都回不来 |
| `struct trapframe` 的 36 个槽 | 中断现场、进程上下文 | 陷阱发生时保存的完整 CPU 状态 | 课上“保存现场”是一句话，实验里是固定偏移的汇编契约；少保存一个寄存器，返回后就少一个值 |
| 系统调用表与 `a0..a5` | 系统调用接口、ABI | 用约定的寄存器和编号传递服务请求 | 课上讲接口语义，实验讲寄存器约定；编号越界必须显式拒绝，不能靠“不会发生” |
| `user_mem_check` | 用户态/内核态隔离、地址空间保护 | 内核不能直接相信用户指针 | 课上讲“用户态不能访问内核”，实验里反过来：内核访问用户指针也要先验证 VMA 权限 |
| `load_icode` 按 `p_memsz` 映射 | 程序加载、ELF、地址空间 | 可执行文件被映射成进程的代码、数据、栈 | 课上讲链接与装入，实验里要自己处理 `p_filesz/p_memsz`、`.bss` 清零和页对齐 |
| `kernel_execve` + `forkrets` | `exec` 语义、特权级下降 | 用新镜像替换当前进程并跳到用户入口 | 课上 `exec` 是系统调用；实验里内核线程没有用户现场，只能手工改写 trapframe，再借 `sret` 下降。RISC-V 的 S 态 `ecall` 走 SBI，不能拿来做这件事 |
| `do_fork` + `copy_mm` + `copy_thread` | 进程创建、`fork` | 子进程复制父进程的地址空间和执行现场 | 课上 `fork` 一次调用返回两次，实验里是两套现场（`trapframe` 和 `context`）分别构造 |
| COW + `PTE_COW` + 引用计数 | 写时复制、页面共享 | 共享只读页，写时再复制 | 课上讲“延迟复制”，实验里要同时维护页表权限、引用计数和 TLB，三者缺一不可 |
| `do_exit` 不释放自己的 PCB/内核栈 | 僵尸进程、进程回收 | 退出进程保留最小状态供父进程读取 | 课上讲僵尸状态，实验里它对应“不能释放自己正在使用的栈”这一硬约束 |
| `do_wait` + 孤儿重挂 | 父子进程、`wait`、孤儿 | 父进程回收子进程，失去父进程的进程被重新收养 | 课上讲进程树，实验里 `cptr/yptr/optr` 三个指针必须同时维护，漏一个就会链表断裂 |
| `schedule` + `need_resched` | 调度、抢占 | 选择下一个可运行进程并切换现场 | 课上讲时间片和优先级，实验只有时钟置位 + 轮转扫描，没有优先级和配额 |
| `switch_to` 只保存 `ra/sp/s0-s11` | 上下文切换、调用约定 | 切换时只保存 callee-saved 现场 | 课上不限定保存范围，实验证明范围由 ABI 决定；caller-saved 由调用者自己负责 |

我们最深的体会是：课上的名词是“结论”，实验里的名词是“不变量”。页表、引用计数、TLB 必须同时正确；`current`、`satp`、`sp` 必须同时指向同一个进程；`trapframe`、内核栈、PCB 必须互相对齐。任何一个“看起来能跑”的实现，只要有一条不变量不成立，就会在某个测试用例里以完全不同的现象暴露出来。

## 六、OS 原理中重要但本实验未覆盖的知识点

1. **抢占式调度与时间片**：本实验只有时钟中断置 `need_resched`，没有优先级、配额和多级反馈队列。
2. **多核同步**：只有单核关中断和简单的自旋锁，没有多核缓存一致性、内存屏障和无锁数据结构。
3. **文件系统与块设备**：用户程序嵌入内核镜像，没有打开、读写、目录和持久化。
4. **按需分页与页面置换**：只有栈增长和 COW 两种缺页，没有磁盘换入换出、LRU/Clock 等置换算法。
5. **信号与进程间通信**：没有信号、管道、共享内存和消息队列。
6. **线程库与用户态线程**：`CLONE_VM` 只提供了内核侧共享地址空间的能力，没有 pthread 级别的线程管理和 TLS。
7. **安全与权限**：没有用户 ID、文件权限、能力机制和地址空间随机化。
8. **死锁与并发控制**：只有局部关中断，没有资源分配图、死锁检测和避免。

## 七、AI 协作与小组讨论

### 7.1 我们怎样写 spec 和 prompt

每个模块先写“输入、成功语义、失败语义、不变量”四段，再让 AI 生成代码。比如模块一的 spec 先固定 ABI 和 trapframe 布局，再写“只允许改哪些文件”；模块二的 spec 先固定 `load_icode` 的段处理顺序，再写“失败路径必须释放什么”。这样比直接说“实现系统调用”少走很多弯路。

prompt 里最重要的一句不是“要实现什么”，而是“不要碰什么”。本实验三个人加 AI 同时改 `proc.c`，如果不写清区域冻结，AI 很容易顺手重写 `do_fork` 或 `do_exit`，把别人的模块覆盖掉。

### 7.2 AI 生成的代码哪里最容易错

我们的经验是：AI 对“正常路径”写得很快，对“边界”和“现场”最容易想当然。典型的有：

- 只考虑 U→S，不考虑 S→S 的 `sscratch`。
- 只按 `p_filesz` 映射，忘记 `.bss`。
- 直接调用 `do_execve`，忘记 `sret`。
- 用户指针不检查，默认“用户不会传坏地址”。
- `va_arg` 的类型和调用点不一致。

这些问题共同点是：编译不报错，静态看也“很像对的”，只有跑到特定用例才暴露。所以我们的验收顺序固定为“先看第一条用户输出，再看系统调用返回值，再看 fork 的父子 PID，最后看 exit/wait 的进程树断言”，不跳步。

### 7.3 小组讨论中的三个分歧

1. **`kernel_execve` 要不要走 `ecall`。** 我们一开始认为 S 态 `ecall` 更自然，能让 `trap()` 顺手拿到 trapframe；实际跑起来才发现 RISC-V 把 S 态 `ecall` 交给 SBI，根本不进 `stvec`。改成直接 `do_execve + forkrets` 后链路才闭合。这个分歧的结论不是“哪种写法更好看”，而是“必须先把平台的异常模型搞清楚”。
2. **COW 要不要默认开启。** 一种意见是先保证 `fork` 全量复制，COW 作为可选开关；另一种是默认 COW。我们保留 `LAB5_NO_COW` 开关，默认 COW，但要求全量复制路径也能通过 `forktest`，这样 COW 出问题时可以快速对照。
3. **日志和截图要不要提前写进报告。** 我们坚持只写实际产生的证据，构建、QEMU、GDB 和评分由宋秋实统一执行后归档，报告里的结论必须能指回日志文件。

### 7.4 反思

第一版我们最容易犯的错是把“能打印”当成“正确”。`pgdir` 能打印但看的是 boot 页表，`kernel_execve` 返回 0 但用户程序没跑，`sys_wait` 能返回但没检查用户指针。这些都不会立刻崩溃，却会在助教检查或后续 lab 里变成更难查的问题。后来我们把每个模块的验收改成“行为 + 不变量”两条：不仅看输出，还要看页表、引用计数、`satp`、`sscratch` 是否符合预期。

另一个反思是测试顺序。如果一开始直接跑 `forktree`，第一个 `sret` 失败时日志里会全是页故障，根本分不清是陷阱入口还是 `load_icode`。所以验收顺序固定为先 `hello`、再 `exit`、再 `forktest`、最后 `forktree`，每一层的问题都能单独定位。
