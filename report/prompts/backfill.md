# Lab2/Lab3 依赖移植说明

Lab4 的进程调度依赖物理内存管理和陷阱处理，但骨架只给了 Lab4 的文件，缺 Lab2/Lab3 的部分，需要回填：

- **物理页分配器**（`kern/mm/default_pmm.c` + `kern/mm/pmm.c` 的 `page_init`）：补 best-fit 分配器（`default_init`/`default_init_memmap`/`default_alloc_pages`/`default_free_pages`）和 `page_init`（从设备树拿物理内存起止，建 `pages[]` 描述符数组、标保留、把空闲区交给分配器）。用 best-fit 是因为官方测试 `best_fit_check` 的断言（`p0+4 == p1`）只有 best-fit 能满足。
- **陷阱恢复与处理**（`kern/trap/trapentry.S` + `kern/trap/trap.c`）：补 `RESTORE_ALL` 宏、`__alltraps` 入口（`mv a0, sp; jal trap; j __trapret`），以及 `interrupt_handler`/`exception_handler`（定时器中断续订下一次事件、计数、到点关机）。

回填保持旧实验语义，但按新骨架接口调整（分配器函数统一成 `default_*`、注册成 `default_pmm_manager`），没有用旧实验整文件覆盖新骨架。
