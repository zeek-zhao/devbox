#!/usr/bin/env bash
set -euo pipefail

WORK="${TMPDIR:-/tmp}/devbox-L2-007-ubsan-overflow"
rm -rf "$WORK"
mkdir -p "$WORK"
trap 'rm -rf "$WORK"' EXIT

gcc -std=c17 -g -O0 -fsanitize=undefined -fno-sanitize-recover=undefined main.c -o "$WORK/example"
if "$WORK/example" >"$WORK/stdout.log" 2>"$WORK/stderr.log"; then
    echo "UBSan: expected failure was not detected" >&2
    exit 1
fi
if ! grep -q 'runtime error:' "$WORK/stderr.log"; then
    echo "UBSan: expected diagnostic was not found" >&2
    exit 1
fi
echo "UBSan: runtime error detected"
