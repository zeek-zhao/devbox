#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L1-034-sorting-determinism"
go build -o "$OUT" main.go
"$OUT"
