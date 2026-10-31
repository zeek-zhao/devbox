#!/usr/bin/env bash
set -euo pipefail

CXX="${CXX:-g++}"
BUILD="${TMPDIR:-/tmp}/devbox-cpp-L2-006-sanitizers"
OUT="$BUILD/sanitizer-demo"
LOG="$BUILD/asan.log"
mkdir -p "$BUILD"

"$CXX" -std=c++20 -Wall -Wextra -pedantic -fsanitize=address -fno-omit-frame-pointer main.cpp -o "$OUT"

# This example expects the instrumented program to fail after ASan detects the heap overflow.
if "$OUT" >"$LOG" 2>&1; then
  printf 'ASan did not detect the expected heap overflow\n' >&2
  exit 1
fi

if grep -q 'AddressSanitizer: heap-buffer-overflow' "$LOG"; then
  printf 'asan: heap-buffer-overflow\n'
else
  cat "$LOG" >&2
  exit 1
fi

# Detection is the successful outcome for this one intentional sanitizer failure.
exit 0
