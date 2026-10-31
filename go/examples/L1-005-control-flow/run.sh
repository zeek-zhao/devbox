#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L1-005-control-flow"
go build -o "$OUT" main.go
"$OUT"
