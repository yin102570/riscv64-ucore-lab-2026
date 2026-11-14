# Lab4 边界测试 T1-T8 结论

运行者：宋秋实（2410749）。测试源码与注入脚本放在本目录，不进入默认评分路径（`make grade` 用官方 `tools/test_lab4.c`）。

## 结论总表

| 编号 | 测试目的 | 结果 | 证据 |
|---|---|---|---|
| T1 | 同页重复映射（引用计数、空闲页数不变） | PASS | `test_boundary_t1t4.c` |
| T2 | 同一地址改映射到另一页 + 权限更新 | PASS | 同上 |
| T3 | 幂等删除（重复 page_remove 不崩溃） | PASS | 同上 |
| T4 | TLB 一致性（改映射后读写走新页） | PASS | 同上 |
| T5 | idleproc/initproc 字段 | PASS | 官方 `test_lab4_process_create` |
| T6 | 调度公平性（两个测试线程均运行） | PASS | 官方 `test_lab4_schedule` |
| T7 | 首次运行链 | PASS | `report/logs/static/gdb-switch.log` |
| T8 | do_fork 失败清理（错误码 + 进程计数不变） | PASS | `test_boundary_t8.c` + `run_boundary_t8.py` |

## 运行输出（T1-T4）

```
[Boundary T1] PASS
[Boundary T2] PASS
[Boundary T3] PASS
[Boundary T4] PASS
[Boundary] all PMM boundary tests done.
```

## 运行输出（T8）

```
[Boundary T8a] setup_kstack fail -> -E_NO_MEM, nr_process unchanged OK
[Boundary T8b] alloc_proc fail -> -E_NO_FREE_PROC, nr_process unchanged OK
[Boundary T8] PASS
```

## 测试发现与记录

1. **可写页必须 `PTE_R | PTE_W`**：单独 `PTE_W`（W=1、R=0）在 RISC-V 是保留组合，实际访问会 fault。官方 `test_lab4.c` 只用 `PTE_W` 是因为它只查 PTE 内容、不真正访问地址；T4 因为要真实读写，必须用 `PTE_R | PTE_W`。

2. **T1 的 `nr_free_pages` 要在首次 `page_insert` 之后采样**：第一次插入会合法分配两级页表页。

3. **T4 需要额外持有旧页引用**：改映射会释放旧页的映射引用，若不额外 `page_ref_inc(p1)`，测试里再读 `page2kva(p1)` 就变成 use-after-free。已修。

4. **T8 只验证了错误码和进程计数**：`nr_process` 不变已覆盖「不挂半初始化 PCB」；链表/哈希完整性未单独断言（进程计数不变 + 无崩溃已能说明清理路径正常）。资源泄漏（空闲页数）未断言，因为 slob 分配器会缓存页、`nr_free_pages` 不精确。

## 复现方式

- T1-T4：`run_boundary.py`（注入到 `/tmp/lab4_boundary` 临时副本运行）
- T8：`run_boundary_t8.py`（注入到 `/tmp/lab4_boundary_t8` 临时副本，含故障注入开关 `force_alloc_proc_fail` / `force_setup_kstack_fail` 和 `get_nr_process()`）

两个脚本都不触碰实际代码树，只在临时副本中注入。
