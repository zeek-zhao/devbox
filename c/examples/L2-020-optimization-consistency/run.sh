#!/usr/bin/env bash
set -euo pipefail

WORK="${TMPDIR:-/tmp}/devbox-L2-020-optimization-consistency"
rm -rf "$WORK"
mkdir -p "$WORK"
trap 'rm -rf "$WORK"' EXIT

gcc -std=c17 -Wall -Wextra -Werror -O0 main.c -o "$WORK/o0"
gcc -std=c17 -Wall -Wextra -Werror -O2 main.c -o "$WORK/o2"
"$WORK/o0" >"$WORK/o0.out"
"$WORK/o2" >"$WORK/o2.out"
if ! cmp -s "$WORK/o0.out" "$WORK/o2.out"; then
    echo "optimization: outputs differ" >&2
    exit 1
fi
cat "$WORK/o0.out"
