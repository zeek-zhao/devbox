#!/usr/bin/env bash
# 用例 hello —— 验证 C++ 镜像能编译并运行 C++20
set -euo pipefail

CXX="${CXX:-g++}"
OUT="${TMPDIR:-/tmp}/devbox-hello-cpp"

"$CXX" -std=c++20 -O2 -Wall -Wextra -o "$OUT" hello.cpp
"$OUT"
