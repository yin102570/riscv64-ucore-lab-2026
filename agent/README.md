# agent 同步（dsh）

> 目标：三台机器的 dsh **行为完全一致**，让同一张提示词卡在任何人的机器上都能逐字复现。
> 同步单位 = 本目录里的两个文件：`dsh.patch.yml`（配置）+ `dsh-web.sh`（启动入口）。

## 一、三步接入（每个成员做一次）

```bash
# 1) 装 dsh（三人都装同一个版本）
npm install -g @deepseek-ai/dsh@0.1.5-rc.3
dsh --version          # 确认 0.1.5-rc.3

# 2) 配自己的 API Key（Web 界面左下角「模型」→ 添加 DeepSeek）
#    或直接写 ~/.dsh/.credentials.yaml（见下）。Key 各人自己的，绝不入库。
dsh web                # 先裸起一次，在界面里配 key

# 3) clone 本仓库后，只用统一入口启动
bash agent/dsh-web.sh
```

## 二、同步机制（核心）

- **`agent/dsh.patch.yml`** 钉死两个变量：
  1. **模型** = `deepseek-v4-flash`（= DeepSeek-V4-Flash）
  2. **权限策略** = `workspace-write`（只写工作区，不改系统）
- 谁要改模型/权限 → 改 `dsh.patch.yml` 这一处 → `git commit & push` → 其他人 `git pull` 即完成同步。
- 启动一律走 `agent/dsh-web.sh`，它会自动 `cd` 到仓库根并挂上 patch，**不许裸跑 `dsh web`**（会漏掉统一配置）。

### 可用模型（dsh 实测目录）

| 模型 id | 含义 |
|---|---|
| `deepseek-v4-flash` | DeepSeek-V4-Flash（**当前统一用这个**） |
| `deepseek-flash` | dsh 默认 flash |
| `deepseek-v4-pro` | DeepSeek-V4-Pro |
| `deepseek-v4-flash-vision-exp` | V4-Flash 视觉实验版 |

> 老师若指定别的模型（例如验收要求的某个 Light 版），只改 `dsh.patch.yml` 里 `model:` 一行。

## 三、headless 用法（跑一张卡、取最终回答，适合批量复现）

```bash
dsh --profile headless --patch "$(pwd)/agent/dsh.patch.yml" "<完整提示词卡正文>"
```

## 四、注意事项

1. **API Key 不入库**：key 在各自 `~/.dsh/.credentials.yaml`，`.gitignore` 已排除。
2. **Windows/WSL 分工**：dsh 跑在 Windows；lab 代码的 `make`/`qemu` 在 WSL 里，让 agent 用 `wsl.exe -e bash -lic "..."` 执行编译/运行。
3. **一个会话一张卡**：不共用会话、不在会话里口头改提示词；改提示词只在 git 里的卡片文件改，再开新会话重跑。
4. **取证固定**：每张卡跑完 `git diff > logs/repro/<card>-diff.patch`、`make qemu` 输出存 `logs/run/<card>.log`。
