#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L1-011-maps-comma-ok"
go build -o "$OUT" main.go
"$OUT"
