#!/usr/bin/env bash
set -euo pipefail

WORK="${TMPDIR:-/tmp}/devbox-L2-011-gcc-analyzer"
rm -rf "$WORK"
mkdir -p "$WORK"
trap 'rm -rf "$WORK"' EXIT

gcc -std=c17 -Wall -Wextra -fanalyzer -c main.c -o "$WORK/main.o" 2>"$WORK/analyzer.log"
if ! grep -qi 'leak' "$WORK/analyzer.log"; then
    echo "GCC analyzer: expected leak diagnostic was not found" >&2
    exit 1
fi
echo "GCC analyzer: leak diagnostic detected"
