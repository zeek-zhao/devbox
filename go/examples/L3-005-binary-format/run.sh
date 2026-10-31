#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L3-005-binary-format"
go build -o "$OUT" main.go
"$OUT"
