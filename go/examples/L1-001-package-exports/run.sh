#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L1-001-package-exports"
go build -o "$OUT" .
"$OUT"
