#!/usr/bin/env bash
set -euo pipefail

CXX="${CXX:-g++}"
OUT="${TMPDIR:-/tmp}/devbox-cpp-L3-002-thread-synchronization"

"$CXX" -std=c++20 -Wall -Wextra -pedantic main.cpp -pthread -o "$OUT"
"$OUT"
