#!/usr/bin/env bash
set -euo pipefail

CC="${CC:-gcc}"
OUT="${TMPDIR:-/tmp}/devbox-c-L1-007-array-decay"

"$CC" -std=c17 -O2 -Wall -Wextra -Werror -o "$OUT" main.c
"$OUT"
