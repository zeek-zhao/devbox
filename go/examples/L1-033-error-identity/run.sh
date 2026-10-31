#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L1-033-error-identity"
go build -o "$OUT" main.go
"$OUT"
