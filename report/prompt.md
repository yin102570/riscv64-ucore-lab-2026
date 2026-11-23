# Lab 4 Prompt 与 Spec 记录

本文件是各模块 spec / prompt / 审查清单的索引，与 [report.md](./report.md) 第四部分一一对应。每个模块的完整内容（范围、spec、不变量、最终 prompt、审查清单、实现记录）单独成文：

| 模块 / 内容 | 文件 | 负责人 |
|---|---|---|
| 功能模块一：虚拟内存页操作 | [prompts/module1.md](prompts/module1.md) | 殷佳仪（2410665） |
| 功能模块二：进程创建与初始化 | [prompts/module2.md](prompts/module2.md) | 宋秋实（2410749） |
| 功能模块三：进程调度与上下文切换 | [prompts/module3.md](prompts/module3.md) | 兰雨杉（2412090） |
| Challenge 1：开关中断原理 | [prompts/challenge1.md](prompts/challenge1.md) | 兰雨杉（2412090） |
| Challenge 2：Sv32/Sv39/Sv48 与 `get_pte()` | [prompts/challenge2.md](prompts/challenge2.md) | 殷佳仪（2410665） |
| 依赖移植说明（Lab2/Lab3 回填） | [prompts/backfill.md](prompts/backfill.md) | 兰雨杉（2412090） |

## 使用约定

- 每个模块先写 spec，再写 prompt。spec 描述"输入—成功语义—失败语义—不变量"，prompt 是喂给 AI 的完整任务书。
- prompt 里同时写"要做什么"和"不能做什么"，并写死"只改哪个文件、哪些函数、不碰哪些区域"，避免 AI 整文件重写或越界改别人的模块。
- 要求 AI 输出 `diff` 而不是整文件。
- 最终验收只认两样：官方 `make grade` 分数（30/30）、从日志里读出的证据（首次运行链 GDB 日志等）。

## 环境

| 项目 | 内容 |
|------|------|
| AI 工具 | dsh（DeepSeek Harness）Web 界面 |
| 底层模型 | DeepSeek-V4-Flash |
| 运行环境 | WSL2 Ubuntu 22.04 + `/opt/riscv` 交叉工具链 + qemu-system-riscv64 7.0.0 |
