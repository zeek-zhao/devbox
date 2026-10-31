#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L1-008-arrays"
go build -o "$OUT" main.go
"$OUT"
