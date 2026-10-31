#!/usr/bin/env bash
set -euo pipefail

WORK="${TMPDIR:-/tmp}/devbox-L2-006-asan-bounds"
rm -rf "$WORK"
mkdir -p "$WORK"
trap 'rm -rf "$WORK"' EXIT

gcc -std=c17 -g -O0 -fsanitize=address -fno-omit-frame-pointer main.c -o "$WORK/example"
if "$WORK/example" >"$WORK/stdout.log" 2>"$WORK/stderr.log"; then
    echo "ASan: expected failure was not detected" >&2
    exit 1
fi
if ! grep -q 'heap-buffer-overflow' "$WORK/stderr.log"; then
    echo "ASan: expected diagnostic was not found" >&2
    exit 1
fi
echo "ASan: heap-buffer-overflow detected"
