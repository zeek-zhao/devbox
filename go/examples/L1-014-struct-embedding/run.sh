#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L1-014-struct-embedding"
go build -o "$OUT" main.go
"$OUT"
