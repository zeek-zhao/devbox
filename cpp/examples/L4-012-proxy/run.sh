#!/usr/bin/env bash
set -euo pipefail

CXX="${CXX:-g++}"
OUT="${TMPDIR:-/tmp}/devbox-cpp-L4-012-proxy"

"$CXX" -std=c++20 -Wall -Wextra -pedantic main.cpp -o "$OUT"
"$OUT"
