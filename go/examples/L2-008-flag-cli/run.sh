#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${TMPDIR:-/tmp}/devbox-go-L2-008-flag-cli"
OUT="$OUT_DIR/program"
mkdir -p "$OUT_DIR"
go build -o "$OUT" .
"$OUT" -name=devbox
if "$OUT" -name= >"$OUT_DIR/invalid.stdout" 2>"$OUT_DIR/invalid.stderr"; then
  echo "missing required name: unexpectedly accepted"
  exit 1
else
  grep -q 'Usage of' "$OUT_DIR/invalid.stderr"
  printf 'missing required name: rejected with usage\n'
fi
