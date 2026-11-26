# Lab 5 提示词与环境记录

## 1. 工具与环境

| 项目 | 内容 |
|---|---|
| AI 工具 | dsh（DeepSeek Harness）Web 界面 |
| 底层模型 | DeepSeek-V4-Flash |
| 工作区 | `~/ucore-lab/lab5`（WSL 原生路径） |
| 运行环境 | WSL2 Ubuntu 22.04、riscv64-unknown-elf 交叉工具链、qemu-system-riscv64 7.0.0、OpenSBI `fw_dynamic`、gdb-multiarch |
| 代码基线 | 本组 Lab 4 完成版（`lab4/code`），未使用往届代码 |

## 2. 提示词归档

Lab 5 的完整提示词按模块归档，正文不在此重复，避免同一段 prompt 出现两份、修改后不同步：

- [prompts/module1.md](./prompts/module1.md)：U/S 陷阱入口与返回、系统调用 ABI、表驱动分发、9 个 `sys_*`、用户指针检查、`sys_pgdir`。
- [prompts/module2.md](./prompts/module2.md)：`alloc_proc`、`kernel_thread`、`load_icode`、`kernel_execve`、用户库与链接脚本。
- [prompts/module3.md](./prompts/module3.md)：`do_fork/copy_mm/copy_thread`、`CLONE_VM`、`get_pid` 时序、失败回滚、COW 二次 fork。
- [prompts/module4.md](./prompts/module4.md)：`do_exit/do_yield/do_kill/do_wait`、僵尸态、孤儿重挂、`wakeup_proc`。
- [prompts/challenge-cow.md](./prompts/challenge-cow.md)：`PTE_COW`、引用计数、写故障状态机、Dirty COW、`cowtest` 用例。
- [prompts/challenge-preload.md](./prompts/challenge-preload.md)：用户 ELF 的构建期嵌入、执行期装载，与文件系统 exec 的差异。

每份文件都包含四部分：问题边界、spec（不变量与失败路径）、最终交给 AI 的 prompt 原文、AI 生成代码暴露的 bug 与修正过程。四个功能模块和两个 Challenge 都已归档，没有待补项。

## 3. 记录约定

后续迭代仍沿用统一格式，时间正序追加到对应模块文件末尾：

```text
### <模块 / 练习名> · 迭代 <序号>
提示词：<完整原文>
结果：<一次通过 / 报错摘要 / 人工修正点>
下一步调整：<改了 prompt 的哪一部分，为什么>
产物：<改动文件>
```

## 4. 运行与静态记录位置

- `report/logs/runtime/`：QEMU 串口输出、`make grade` 结果、GDB 会话记录，由宋秋实统一归档。
- `report/logs/static/`：`objdump`、`readelf`、链接脚本检查等静态证据。
- `report/images/`：报告引用的截图，文件名与正文一一对应。
