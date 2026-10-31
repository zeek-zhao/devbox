#!/usr/bin/env bash
set -euo pipefail

# VCS stamping 会把 commit hash 烙进二进制，同源码不同 commit 产出不同二进制，
# 且 CI 里 .git 属主不一致时 go build 直接 exit 128。必须显式关闭。
export GOFLAGS="-buildvcs=false"
OUT="${TMPDIR:-/tmp}/devbox-go-L4-021-strategy"
go build -o "$OUT" .
"$OUT"
