#!/usr/bin/env bash
set -euo pipefail

CXX="${CXX:-g++}"
OUT="${TMPDIR:-/tmp}/devbox-cpp-L2-008-cli-interface"

"$CXX" -std=c++20 -Wall -Wextra -pedantic main.cpp -o "$OUT"
"$OUT" --query alpha
printf 'exit-code: 0\n'
if "$OUT"; then
  status=0
else
  status=$?
fi
printf 'exit-code: %s\n' "$status"
if [ "$status" -ne 2 ]; then
  printf 'missing query returned an unexpected status\n' >&2
  exit 1
fi
if "$OUT" --unknown; then
  status=0
else
  status=$?
fi
printf 'exit-code: %s\n' "$status"
if [ "$status" -ne 2 ]; then
  printf 'invalid option returned an unexpected status\n' >&2
  exit 1
fi
"$OUT" --help
printf 'exit-code: 0\n'
