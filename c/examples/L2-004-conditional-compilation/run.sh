#!/usr/bin/env bash
set -euo pipefail

WORK="${TMPDIR:-/tmp}/devbox-L2-004-conditional-compilation"
rm -rf "$WORK"
mkdir -p "$WORK"
trap 'rm -rf "$WORK"' EXIT

gcc -std=c17 -Wall -Wextra -Werror -DDEBUG main.c -o "$WORK/debug"
gcc -std=c17 -Wall -Wextra -Werror main.c -o "$WORK/release"
"$WORK/debug"
"$WORK/release"
