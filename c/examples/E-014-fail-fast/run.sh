#!/usr/bin/env bash
set -euo pipefail

CC="${CC:-gcc}"
WORK="${TMPDIR:-/tmp}/devbox-E-014-fail-fast"
rm -rf "$WORK"
mkdir -p "$WORK"
trap 'rm -rf "$WORK"' EXIT

"$CC" -std=c17 -O2 -Wall -Wextra -Werror main.c -o "$WORK/main"

"$WORK/main" ok
set +e
"$WORK/main" fatal
rc=$?
set -e
echo "fatal_exit=$rc"
