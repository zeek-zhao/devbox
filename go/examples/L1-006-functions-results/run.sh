#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L1-006-functions-results"
go build -o "$OUT" main.go
"$OUT"
