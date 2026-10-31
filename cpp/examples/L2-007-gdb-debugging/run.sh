#!/usr/bin/env bash
set -euo pipefail

CXX="${CXX:-g++}"
OUT="${TMPDIR:-/tmp}/devbox-cpp-L2-007-gdb-debugging"

"$CXX" -std=c++20 -Wall -Wextra -pedantic -g main.cpp -o "$OUT"
gdb -batch -ex 'break report_query_error' -ex run -ex bt "$OUT" 2>&1 \
  | sed -E 's/0x[0-9a-f]+/0xADDR/g' \
  | grep -E '^#[0-9]+ ' \
  | sed -E 's/^#[0-9]+[[:space:]]+//; s/^0xADDR in //; s/^in //; s/[[:space:](].*$//; s/^/frame: /'
