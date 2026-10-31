#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L1-003-constants-iota"
go build -o "$OUT" main.go
"$OUT"
