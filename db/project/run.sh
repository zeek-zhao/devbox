#!/usr/bin/env bash
# 毕业项目的端到端：下单 -> 查缓存 -> 出报表 -> 查日志 -> 读快照
set -euo pipefail
cd "$(dirname "$0")/.."
. scripts/lib/common.sh
toolbox_project="$(tb mktemp -d /tmp/db06-project.XXXXXX)"
trap 'tb rm -rf "$toolbox_project"' EXIT
tar -C project -cf - . | tb tar -xf - -C "$toolbox_project"
tb python3 "$toolbox_project/run.py"
