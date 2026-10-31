#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L1-031-fmt-formatting"
go build -o "$OUT" main.go
"$OUT"
