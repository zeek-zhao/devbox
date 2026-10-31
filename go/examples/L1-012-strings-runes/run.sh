#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L1-012-strings-runes"
go build -o "$OUT" main.go
"$OUT"
