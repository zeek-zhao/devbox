#!/usr/bin/env bash
set -euo pipefail

WORK="${TMPDIR:-/tmp}/devbox-L2-015-log-macro"
rm -rf "$WORK"
mkdir -p "$WORK"
trap 'rm -rf "$WORK"' EXIT

gcc -std=c17 -Wall -Wextra -Werror main.c -o "$WORK/example"
"$WORK/example" >"$WORK/output.log"
sed -E 's|main\.c:[0-9]+:|source:LINE:|' "$WORK/output.log"
