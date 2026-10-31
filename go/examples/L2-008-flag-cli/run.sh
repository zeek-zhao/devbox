#!/usr/bin/env bash
set -euo pipefail

# Go 在模块模式下会把 git 版本信息烙进二进制（VCS stamping）。两个问题：
#   1) 二进制里嵌入 commit hash，同一份源码在不同 commit 上产出不同二进制，违反确定性；
#   2) CI 里 .git 属主与容器用户不一致时 git 以 exit 128 拒绝，go build 直接失败。
# 所以显式关闭。
export GOFLAGS="-buildvcs=false"
OUT_DIR="${TMPDIR:-/tmp}/devbox-go-L2-008-flag-cli"
OUT="$OUT_DIR/program"
mkdir -p "$OUT_DIR"
go build -o "$OUT" .
"$OUT" -name=devbox
if "$OUT" -name= >"$OUT_DIR/invalid.stdout" 2>"$OUT_DIR/invalid.stderr"; then
  echo "missing required name: unexpectedly accepted"
  exit 1
else
  grep -q 'Usage of' "$OUT_DIR/invalid.stderr"
  printf 'missing required name: rejected with usage\n'
fi
