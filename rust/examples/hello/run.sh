#!/usr/bin/env bash
# 用例 hello —— 验证 Rust 镜像能编译并运行
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-hello-rust"

rustc -O -o "$OUT" hello.rs
"$OUT"
