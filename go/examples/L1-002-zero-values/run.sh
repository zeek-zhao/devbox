#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L1-002-zero-values"
go build -o "$OUT" main.go
"$OUT"
