#!/usr/bin/env bash
set -euo pipefail

CXX="${CXX:-g++}"
OUT="${TMPDIR:-/tmp}/devbox-cpp-L2-011-error-reporting"

"$CXX" -std=c++20 -Wall -Wextra -pedantic main.cpp -o "$OUT"
if "$OUT" input; then
  status=0
else
  status=$?
fi
printf 'exit-code: %s\n' "$status"
if [ "$status" -ne 2 ]; then
  printf 'input error returned an unexpected status\n' >&2
  exit 1
fi
if "$OUT" storage; then
  status=0
else
  status=$?
fi
printf 'exit-code: %s\n' "$status"
if [ "$status" -ne 3 ]; then
  printf 'storage error returned an unexpected status\n' >&2
  exit 1
fi
