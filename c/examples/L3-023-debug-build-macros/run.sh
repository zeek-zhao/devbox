#!/usr/bin/env bash
set -euo pipefail

ID="L3-023-debug-build-macros"
OUT="${TMPDIR:-/tmp}/devbox-${ID}"
rm -rf "$OUT"
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT

CC="${CC:-gcc}"
"$CC" -std=c17 -O2 -Wall -Wextra -Werror -DDEVBOX_TRACE=1 \
  -o "$OUT/enabled" main.c
"$CC" -std=c17 -O2 -Wall -Wextra -Werror -DDEVBOX_TRACE=0 \
  -o "$OUT/disabled" main.c
"$OUT/enabled"
"$OUT/disabled"
