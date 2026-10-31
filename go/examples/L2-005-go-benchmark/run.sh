#!/usr/bin/env bash
set -euo pipefail

# Go 在模块模式下会把 git 版本信息烙进二进制（VCS stamping）。两个问题：
#   1) 二进制里嵌入 commit hash，同一份源码在不同 commit 上产出不同二进制，违反确定性；
#   2) CI 里 .git 属主与容器用户不一致时 git 以 exit 128 拒绝，go build 直接失败。
# 所以显式关闭。
export GOFLAGS="-buildvcs=false"
OUT="${TMPDIR:-/tmp}/devbox-go-L2-005-go-benchmark"
mkdir -p "$OUT"
go build -o "$OUT/program" .
benchmark_output="$(go test -run '^$' -bench '^BenchmarkTokenize$' -benchtime=1x -count=1 ./...)"
if ! grep -q '^BenchmarkTokenize-' <<<"$benchmark_output"; then
  echo "benchmark-present: false"
  exit 1
fi
printf 'benchmark-present: true\n'
printf 'benchmark-iterations: b.N\n'
