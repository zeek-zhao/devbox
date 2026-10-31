#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L1-035-integer-boundaries"
go build -o "$OUT" main.go
"$OUT"
