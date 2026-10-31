#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L2-006-build-tags"
mkdir -p "$OUT"
go build -o "$OUT/default" .
go build -tags diagnostic -o "$OUT/diagnostic" .
"$OUT/default"
"$OUT/diagnostic"
