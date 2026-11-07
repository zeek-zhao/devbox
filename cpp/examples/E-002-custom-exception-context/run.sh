#!/usr/bin/env bash
set -euo pipefail

CXX="${CXX:-g++}"
OUT="${TMPDIR:-/tmp}/devbox-cpp-E-002-custom-exception-context"

"$CXX" -std=c++20 -Wall -Wextra -pedantic main.cpp -o "$OUT"
"$OUT"
