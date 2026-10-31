#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L1-009-slice-backing-array"
go build -o "$OUT" main.go
"$OUT"
