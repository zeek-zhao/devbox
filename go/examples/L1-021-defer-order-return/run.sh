#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L1-021-defer-order-return"
mkdir -p "$OUT"
export GOCACHE="$OUT/cache"
go build -o "$OUT/example" main.go
"$OUT/example"
