#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L1-030-io-copy"
go build -o "$OUT" main.go
"$OUT"
