#!/usr/bin/env bash
set -euo pipefail

CC="${CC:-gcc}"
WORK="${TMPDIR:-/tmp}/devbox-E-011-deadline-cancel"
rm -rf "$WORK"
mkdir -p "$WORK"
trap 'rm -rf "$WORK"' EXIT

"$CC" -std=c17 -O2 -Wall -Wextra -Werror main.c -o "$WORK/main"
"$WORK/main"
