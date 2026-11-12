#!/usr/bin/env bash
# T-001-goroutine-leak 最小复现：plain 构建缺陷版本并稳定触发一次 goroutine 泄漏，
# 用 runtime.NumGoroutine 前后对照坐实（before/after/delta）。
# 按 docs/72 §2 样板约定：复现成功 = 泄漏被坐实 = 本脚本以非零退出码结束，
# 证据行（LEAK-CONFIRMED）原样打到 stdout（由调用方归一化后再断言）。
# 构建产物只写临时目录，不入库。用法：bash repro.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

GO="${GO:-go}"
BUILD="${TMPDIR:-/tmp}/devbox-go-T-001-goroutine-leak"
OUT="$BUILD/buggy-leak"
mkdir -p "$BUILD"

"$GO" build -buildvcs=false -o "$OUT" . || { echo "repro: go build 失败" >&2; exit 2; }

# 稳定复现一次：观测判据 delta>=90 必然成立并以退出码 1 结束。
"$OUT" 2>&1
rc=$?
if [ "$rc" -eq 0 ]; then
  echo "repro: 泄漏未被触发（delta<90，环境异常，见 WALKTHROUGH 决策树 Q0 分支）" >&2
  exit 3
fi
exit "$rc"
