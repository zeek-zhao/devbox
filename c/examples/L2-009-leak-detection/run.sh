#!/usr/bin/env bash
set -euo pipefail

WORK="${TMPDIR:-/tmp}/devbox-L2-009-leak-detection"
rm -rf "$WORK"
mkdir -p "$WORK"
trap 'rm -rf "$WORK"' EXIT

gcc -std=c17 -g -O0 -fsanitize=address -fno-omit-frame-pointer main.c -o "$WORK/example"
if ASAN_OPTIONS=detect_leaks=1 "$WORK/example" >"$WORK/stdout.log" 2>"$WORK/stderr.log"; then
    echo "LeakSanitizer: expected leak was not detected" >&2
    exit 1
fi
if ! grep -q 'LeakSanitizer' "$WORK/stderr.log"; then
    echo "LeakSanitizer: expected diagnostic was not found" >&2
    exit 1
fi
echo "LeakSanitizer: leak detected"
