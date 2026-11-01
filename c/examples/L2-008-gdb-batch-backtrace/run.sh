#!/usr/bin/env bash
set -euo pipefail

WORK="${TMPDIR:-/tmp}/devbox-L2-008-gdb-batch-backtrace"
rm -rf "$WORK"
mkdir -p "$WORK"
trap 'rm -rf "$WORK"' EXIT

gcc -std=c17 -g -O0 main.c -o "$WORK/example"
gdb -batch -ex run -ex bt --args "$WORK/example" >"$WORK/gdb.log" 2>&1
if ! grep -q 'crash_here' "$WORK/gdb.log"; then
    echo "gdb: expected function was not found in backtrace" >&2
    exit 1
fi
echo "gdb: crash_here found in backtrace"
