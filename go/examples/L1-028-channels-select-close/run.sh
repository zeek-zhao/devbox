#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L1-028-channels-select-close"
go build -o "$OUT" main.go
"$OUT"
