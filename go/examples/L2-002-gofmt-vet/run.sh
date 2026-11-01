#!/usr/bin/env bash
set -euo pipefail

# Go 在模块模式下会把 git 版本信息烙进二进制（VCS stamping）。两个问题：
#   1) 二进制里嵌入 commit hash，同一份源码在不同 commit 上产出不同二进制，违反确定性；
#   2) CI 里 .git 属主与容器用户不一致时 git 以 exit 128 拒绝，go build 直接失败。
# 所以显式关闭。
export GOFLAGS="-buildvcs=false"
OUT="${TMPDIR:-/tmp}/devbox-go-L2-002-gofmt-vet"
mkdir -p "$OUT/source"
cp go.mod ./*.go "$OUT/source/"

# ------------------------------------------------------------------
# 本用例的考点是「gofmt 能检出未格式化的源码」，所以它必须拿到一份
# 未格式化的 main.go。
#
# 这份夹具不能当仓库源码存着：仓库已经引入统一格式化（make fmt），
# 存一份未格式化文件会让 make fmt-check 永远报差异；而一旦被 make fmt
# 修好，本用例的前提就没了，会直接失败。
#
# 所以夹具改成运行时现场生成 —— 仓库里的 main.go 保持格式化，
# 测试用的这份保持未格式化，两边各自成立。
# ------------------------------------------------------------------
cat > "$OUT/source/main.go" <<'UNFORMATTED_MAIN'
package main

import "fmt"

func main(){fmt.Println("quality-gates: passed")}
UNFORMATTED_MAIN

cd "$OUT/source"
unformatted="$(gofmt -l ./*.go)"
if [ -z "$unformatted" ]; then
  echo "gofmt-detected-unformatted: false"
  exit 1
fi
printf 'gofmt-detected-unformatted: true\n'
gofmt -w ./*.go
remaining="$(gofmt -l ./*.go)"
if [ -n "$remaining" ]; then
  echo "gofmt-clean: false"
  exit 1
fi
printf 'gofmt-clean: true\n'
if ! go vet ./...; then
  echo "go-vet: failed"
  exit 1
fi
printf 'go-vet: passed\n'
if ! go test ./... >/dev/null; then
  echo "go-test: failed"
  exit 1
fi
printf 'go-test: passed\n'
go build -o "$OUT/program" .
"$OUT/program"
