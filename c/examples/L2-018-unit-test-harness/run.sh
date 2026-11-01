#!/usr/bin/env bash
set -euo pipefail

WORK="${TMPDIR:-/tmp}/devbox-L2-018-unit-test-harness"
rm -rf "$WORK"
mkdir -p "$WORK"
trap 'rm -rf "$WORK"' EXIT

gcc -std=c17 -Wall -Wextra -Werror main.c -o "$WORK/example"
"$WORK/example"
