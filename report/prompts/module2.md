# 模块二：创建并加载第一个用户进程

负责人：2410665 殷佳仪

## 1. 问题边界

模块二要回答两个问题：

1. `initproc` 怎样在不借助用户态的情况下再派生一个内核线程，并让它执行指定函数？
2. 这个内核线程怎样把一段 ELF 镜像变成真正的 U 态进程，并从用户入口开始执行？

第一个问题复用 `do_fork()` 的主链，属于进程创建；第二个问题是 `exec` 语义，核心在 `load_icode()` 和“用一次伪造的陷阱返回完成特权级下降”。

## 2. Spec

### 2.1 `alloc_proc()`

PCB 必须完全初始化：`state = PROC_UNINIT`，`pid = -1`，`mm = NULL`，`pgdir = boot_pgdir_pa`，`tf = NULL`，`flags = 0`，`exit_code = 0`，`wait_state = 0`，`cptr/yptr/optr = NULL`，`context` 清零。`pgdir` 存物理地址，因为 `satp` 只接受物理页号。

### 2.2 `kernel_thread()`

构造一个最小 trapframe：

- `s0 = fn`，`s1 = arg`，与 `kernel_thread_entry` 的 `move a0, s1; jalr s0` 对应。
- `status` 置 `SPP | SPIE`、清 `SIE`，保证第一次 `sret` 回到 S 态且开中断。
- `epc = kernel_thread_entry`。

### 2.3 `load_icode()`

输入是一段已经嵌入内核镜像的 ELF。步骤与不变量：

1. 校验 `ELF_MAGIC`、`e_phnum != 0`、程序头表不越过镜像末尾。
2. `mm_create()` + `setup_pgdir()` 建立新地址空间；新页表复制内核高半区映射，清空用户区。
3. 遍历 `PT_LOAD` 段，跳过 `p_memsz == 0` 的空段。
4. 校验 `p_filesz <= p_memsz`、`p_offset + p_filesz <= size`、`[p_va, p_va + p_memsz)` 在用户窗口内。
5. 每个段 `mm_map()` 建 VMA，按 `p_memsz` 而不是 `p_filesz` 映射页；文件内容拷贝后，剩余部分清零，满足 `.bss` 语义。
6. 用户栈建一个 `VM_STACK` VMA，范围 `[USTACKTOP - USTACKSIZE, USTACKTOP)`；最低一页是 guard page，预映射靠近栈顶的 4 页。
7. `mm_count_inc()`、`current->mm = mm`、`current->pgdir = PADDR(mm->pgdir)`、`lsatp()`。
8. 改写 `current->tf`：通用寄存器清零，`sp = USTACKTOP`，`epc = e_entry`，`SPP` 清零，`SPIE` 置 1，`SIE` 清零。

失败路径必须 `exit_mmap()`、`put_pgdir()`、`mm_destroy()`，不能留下半张页表。

### 2.4 `kernel_execve()` 与 `do_execve()`

`do_execve()` 只负责替换地址空间和 trapframe。`kernel_execve()` 在 `do_execve()` 成功后直接调用 `forkrets(current->tf)`：把 `sp` 指向被改写的 trapframe，跳进 `__trapret`，由 `sret` 返回 U 态。不能走 S 态 `ecall`——RISC-V 把它交给 SBI（M 态），不会进 `stvec`；也不能直接函数返回，否则会得到一个“已经换好页表但仍在 S 态”的进程。

`do_execve()` 释放旧 mm 时按 `mm_count_dec()` 判断，不能无条件 `exit_mmap()`；旧地址空间可能被 `CLONE_VM` 的线程共享。切换 `satp` 到 `boot_pgdir_pa` 必须发生在释放旧页表之前。

## 3. 最终提示词

```text
在 ucore lab5 中实现第一个用户进程，只修改 kern/process/proc.c 的
alloc_proc/proc_init/kernel_thread/init_main/user_main/kernel_execve/
do_execve/load_icode 区域，以及 tools/user.ld 和用户库。

要求：
1. alloc_proc 初始化全部字段，pgdir 用物理地址 boot_pgdir_pa。
2. kernel_thread 用 s0=fn、s1=arg 构造 trapframe，epc 指向
   kernel_thread_entry，status 置 SPP|SPIE、清 SIE。
3. init_main 创建 user_main 后循环 do_wait(0, NULL)，等所有用户进程
   退出后断言 nr_process==2 且 initproc 的子进程链为空，再常驻睡眠。
4. user_main 用 KERNEL_EXECVE 选择镜像；kernel_execve 在 do_execve
   成功后调用 forkrets(current->tf)，借 __trapret/sret 下降，不能走
   S 态 ecall，也不能直接函数返回。
5. load_icode 校验 ELF 头、程序头表、每段范围；按 p_memsz 建 VMA 和
   映射，p_filesz 之外清零；跳过 p_memsz==0 的段。
6. 用户栈建 VM_STACK VMA，最低页是 guard page，预映射 4 页。
7. 改写 trapframe 时清 SPP、置 SPIE、清 SIE，sp=USTACKTOP，epc=e_entry。
8. 所有失败路径释放 mm、页表和 VMA，不泄漏。
9. 用户链接脚本保证每个 PT_LOAD 段页对齐，避免 mm_map 的 ROUNDDOWN/
   ROUNDUP 造成相邻 VMA 重叠。
```

## 4. 迭代与 bug

### 4.1 `.bss` 没有清零

第一版只按 `p_filesz` 拷贝并映射，`.bss` 段虽然出现在程序头里，但 `p_memsz > p_filesz` 的尾部没有页。`testbss` 里未初始化的全局变量读到的是上一任页主的残留数据，断言随机失败。修复是按 `p_memsz` 计算映射范围，整页 `memset` 清零后再拷贝文件内容。

### 4.2 段与段之间页重叠

链接脚本最初只有 `.data` 前有 `ALIGN(0x1000)`。`.text`/`.rodata` 结束在页中间时，`mm_map()` 的 `ROUNDUP` 会把 VMA 扩到页尾，下一段的 `ROUNDDOWN` 又从同一页开始，`insert_vma_struct()` 直接断言重叠。修复是每个段前都加 `. = ALIGN(0x1000)`，让 ELF 的 `p_va` 本身页对齐。

### 4.3 空段产生零长度 VMA

某些工具链会生成 `p_memsz == 0` 的 `PT_LOAD`。第一版直接 `mm_map(mm, va, 0, ...)`，`vma_create(start, start, ...)` 得到一个空 VMA，后续 `find_vma()` 和 `exit_mmap()` 的行为都不对。修复是在段循环开头同时跳过 `p_type != PT_LOAD` 和 `p_memsz == 0`。

### 4.4 程序装好了却没有运行

第一版 `kernel_execve()` 直接调用 `do_execve()`，返回 0 后 `user_main()` 继续执行 `panic("user_main execve failed")`。日志显示 `ret = 0`，但没有任何用户输出。根因是 `load_icode()` 只改了 `current->tf`，CPU 仍在 S 态执行内核线程。第二版改成 S 态 `ecall`，结果被 SBI 接走，仍然不进 `stvec`。最终修复是 `do_execve()` 成功后 `forkrets(current->tf)`：`sp` 指向改写后的 trapframe，`__trapret` 恢复寄存器后 `sret` 完成 U 态切换。

### 4.5 `sret` 回到了内核态

构造 trapframe 时只改了 `epc` 和 `sp`，忘记清 `sstatus.SPP`。`sret` 按 SPP=1 返回 S 态，用户入口地址在 U 页上，立刻触发取指页故障。修复是把 `status` 改为 `(status & ~SPP) | SPIE`，再清 `SIE`，让硬件在 `sret` 时用 `SPIE` 恢复用户态中断使能。

### 4.6 `init_main` 把成功当失败

`kernel_thread()` 成功时返回子进程 PID，第一次是 2。`init_main()` 最初写的是 `if (kernel_thread(...) != 0) panic(...)`，于是父进程刚创建 `user_main` 就 panic。把判断改成 `<= 0` 后，0 以下才是错误码，正数就是子进程 PID。

### 4.7 用户栈第一次压栈就故障

只建了 `VM_STACK` VMA，没有预映射任何页。`sp = USTACKTOP` 后第一条压栈访问 `USTACKTOP - 16`，页故障进入 `do_pgfault()`；虽然栈 VMA 允许扩展，但 `la < vm_start + PGSIZE` 的 guard 判断和初始页的边界很容易写错。修复是预映射靠近栈顶的 4 页，并在 `do_pgfault()` 中保留 guard page 检查。

### 4.8 `mm_count` 与释放顺序

`load_icode()` 成功后 `mm_count_inc()` 再赋给 `current->mm`；失败路径的 `mm_count` 仍为 0，才能安全 `exit_mmap()`。`do_execve()` 先 `lsatp(boot_pgdir_pa)` 再释放旧 mm，否则释放过程中仍在用即将销毁的页表。`CLONE_VM` 的 `copy_mm()` 必须同时复制 `proc->pgdir = PADDR(oldmm->pgdir)`，否则子线程第一次被调度时 `satp` 指向旧值。

### 4.9 用户库的变参类型

`syscall(int num, ...)` 用 `va_arg(ap, uintptr_t)` 读参数，但调用点传的是 `int`。在 LP64 下 `int` 只占 32 位，按 64 位读取会把相邻寄存器/栈槽拼进来，表现为 `sys_wait` 的 pid 或 `sys_putc` 的字符随机错。修复是所有整型参数在 `sys_*` 包装里显式转 `(uintptr_t)(intptr_t)`，保证变参提升后的宽度一致。

## 5. 静态自查清单

- `alloc_proc()` 的每个字段都有初值，`pgdir` 是物理地址。
- `kernel_thread()` 的 `s0/s1` 与 `entry.S` 的 `move a0, s1; jalr s0` 对应。
- `init_main()` 不返回，`user_main()` 失败才 panic。
- `load_icode()` 的每个失败分支都释放 mm。
- 每个 `PT_LOAD` 段的 `p_va` 页对齐，`p_memsz` 覆盖 `.bss`。
- 用户栈有 guard page，预映射页不与代码段重叠。
- `tf->status` 的 SPP/SPIE/SIE 三位符合 U 态返回要求。
- `do_execve()` 先切 `satp` 再释放旧页表。
