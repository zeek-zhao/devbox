#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L1-017-type-assertions"
go build -o "$OUT" main.go
"$OUT"
