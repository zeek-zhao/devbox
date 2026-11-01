#!/usr/bin/env bash
# 用例 hello —— 验证 Go 镜像能编译并运行，且 goroutine 可用
set -euo pipefail

go run hello.go
