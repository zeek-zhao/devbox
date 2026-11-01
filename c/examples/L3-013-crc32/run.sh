#!/usr/bin/env bash
set -euo pipefail

ID="L3-013-crc32"
OUT="${TMPDIR:-/tmp}/devbox-${ID}"
rm -rf "$OUT"
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT

CC="${CC:-gcc}"
"$CC" -std=c17 -O2 -Wall -Wextra -Werror -o "$OUT/example" main.c
"$OUT/example"
