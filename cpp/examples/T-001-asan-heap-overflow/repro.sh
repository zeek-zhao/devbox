#!/usr/bin/env bash
# T-001-asan-heap-overflow 最小复现：编译带缺陷版本（ASan 插桩）并稳定触发一次堆越界。
# 按 docs/72 §2 样板约定：复现成功 = 故障被触发 = 本脚本以非零退出码结束，
# ASan 报告原样打到 stdout/stderr（由调用方归一化后再断言）。
# 构建产物只写临时目录，不入库。用法：bash repro.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

CXX="${CXX:-g++}"
BUILD="${TMPDIR:-/tmp}/devbox-cpp-T-001-asan-heap-overflow"
OUT="$BUILD/buggy-asan"
mkdir -p "$BUILD"

"$CXX" -std=c++20 -Wall -Wextra -pedantic -g -O0 -fno-omit-frame-pointer \
  -fsanitize=address main.cpp -o "$OUT" || { echo "repro: 编译失败" >&2; exit 2; }

# 稳定复现一次：ASan 构建必报 heap-buffer-overflow 并以非零退出。
"$OUT" 2>&1
rc=$?
if [ "$rc" -eq 0 ]; then
  echo "repro: 程序退出码 0，越界未被触发（环境异常，见 WALKTHROUGH 决策树「先确认二进制真的被执行过」分支）" >&2
  exit 3
fi
exit "$rc"
