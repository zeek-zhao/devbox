#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L1-015-method-receivers"
go build -o "$OUT" main.go
"$OUT"
