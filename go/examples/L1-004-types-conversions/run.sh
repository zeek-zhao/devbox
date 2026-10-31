#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L1-004-types-conversions"
go build -o "$OUT" main.go
"$OUT"
