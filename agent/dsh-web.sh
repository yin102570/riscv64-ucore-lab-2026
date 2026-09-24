#!/usr/bin/env bash
# 三人统一的 dsh 启动入口（agent 同步的落点之一）
#
# 用法（在仓库根目录执行）：
#   bash agent/dsh-web.sh            # 启动 web 界面
#   bash agent/dsh-web.sh --port 8080  # 换端口（透传给 dsh web）
#
# 它做了两件事：
#   1) 把工作目录切到仓库根（workspace = 仓库根）
#   2) 自动挂上 agent/dsh.patch.yml（统一模型 + 权限策略）
#
# 这样三台机器只要 git pull 后跑同一个脚本，行为就完全一致。
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/.." && pwd)"
PATCH="$HERE/dsh.patch.yml"

cd "$REPO_ROOT"
exec dsh web --patch "$PATCH" "$@"
