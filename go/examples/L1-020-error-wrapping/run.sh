#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L1-020-error-wrapping"
mkdir -p "$OUT"
export GOCACHE="$OUT/cache"
go build -o "$OUT/example" main.go
"$OUT/example"
