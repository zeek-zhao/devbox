#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L1-010-slice-capacity"
go build -o "$OUT" main.go
"$OUT"
