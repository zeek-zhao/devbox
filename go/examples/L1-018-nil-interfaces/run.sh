#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L1-018-nil-interfaces"
go build -o "$OUT" main.go
"$OUT"
