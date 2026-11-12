#!/usr/bin/env bash
# T-001-borrow-trait-conflict 最小复现：rustc 编译带缺陷版本，稳定触发一次特征冲突编译错。
# 按 docs/72 §2 样板约定：复现成功 = 故障被触发 = 本脚本以非零退出码结束，
# rustc 诊断原样打到 stdout/stderr（由调用方归一化后再断言）。
# 构建产物只写临时目录，不入库。用法：bash repro.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

RUSTC="${RUSTC:-rustc}"
BUILD="${TMPDIR:-/tmp}/devbox-rust-T-001-borrow-trait-conflict"
mkdir -p "$BUILD"

"$RUSTC" --edition 2021 main.rs -o "$BUILD/buggy" 2>&1
rc=$?
if [ "$rc" -eq 0 ]; then
  echo "repro: 编译竟通过，特征冲突未被触发（环境异常，见 WALKTHROUGH 决策树「先确认诊断来自这份源码」分支）" >&2
  exit 3
fi
exit "$rc"
