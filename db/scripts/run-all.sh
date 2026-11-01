#!/usr/bin/env bash
# 起环境 -> 等就绪 -> 跑全部用例 -> 汇总（不自动关，便于排查）
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1
bash scripts/up.sh
bash scripts/wait-ready.sh
exec bash scripts/run-example.sh db --all
