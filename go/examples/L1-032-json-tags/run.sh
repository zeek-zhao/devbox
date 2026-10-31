#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L1-032-json-tags"
go build -o "$OUT" main.go
"$OUT"
