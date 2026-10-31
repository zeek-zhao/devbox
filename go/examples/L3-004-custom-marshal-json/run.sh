#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L3-004-custom-marshal-json"
go build -o "$OUT" main.go
"$OUT"
