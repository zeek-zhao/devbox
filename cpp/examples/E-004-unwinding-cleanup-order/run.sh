#!/usr/bin/env bash
set -euo pipefail

CXX="${CXX:-g++}"
OUT="${TMPDIR:-/tmp}/devbox-cpp-E-004-unwinding-cleanup-order"

"$CXX" -std=c++20 -Wall -Wextra -pedantic main.cpp -o "$OUT"
"$OUT"
