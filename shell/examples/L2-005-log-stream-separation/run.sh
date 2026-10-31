#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L2-005-log-stream-separation.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

bash demo.sh >"$WORK/stdout" 2>"$WORK/stderr"
grep -Fxq 'result=deployed' "$WORK/stdout"
grep -Fxq 'progress=deploying' "$WORK/stderr"
test "$(wc -l <"$WORK/stdout")" -eq 1
test "$(wc -l <"$WORK/stderr")" -eq 1
cat "$WORK/stdout"
