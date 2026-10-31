#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L1-029-directional-channels"
go build -o "$OUT" main.go
"$OUT"
