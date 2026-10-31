#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L1-016-interfaces-method-sets"
go build -o "$OUT" main.go
"$OUT"
