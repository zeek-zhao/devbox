#!/usr/bin/env bash
set -euo pipefail

CXX="${CXX:-g++}"
OUT="${TMPDIR:-/tmp}/devbox-cpp-L3-003-atomics-memory-order"

"$CXX" -std=c++20 -Wall -Wextra -pedantic main.cpp -pthread -o "$OUT"
"$OUT"
