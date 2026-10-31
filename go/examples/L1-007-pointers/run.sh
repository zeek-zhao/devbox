#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L1-007-pointers"
go build -o "$OUT" main.go
"$OUT"
