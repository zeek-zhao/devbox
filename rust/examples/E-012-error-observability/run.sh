#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
BIN="$WORK/e-012-error-observability"
rustc --edition=2021 -O -D warnings main.rs -o "$BIN"

# stdout 与 stderr 分流捕获，先回放业务输出，再回放诊断流。
"$BIN" >"$WORK/stdout.txt" 2>"$WORK/stderr.txt"
cat "$WORK/stdout.txt"
echo "-- stderr --"
cat "$WORK/stderr.txt"
