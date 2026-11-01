#!/usr/bin/env bash
set -euo pipefail

WORK="${TMPDIR:-/tmp}/devbox-L2-005-assert-ndebug"
rm -rf "$WORK"
mkdir -p "$WORK"
trap 'rm -rf "$WORK"' EXIT

gcc -std=c17 -Wall -Wextra -Werror main.c -o "$WORK/assert-enabled"
gcc -std=c17 -Wall -Wextra -Werror -DNDEBUG main.c -o "$WORK/assert-disabled"
"$WORK/assert-enabled"
"$WORK/assert-disabled"
