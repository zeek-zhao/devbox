#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L3-006-tcp-echo"
go build -o "$OUT" main.go
"$OUT"
