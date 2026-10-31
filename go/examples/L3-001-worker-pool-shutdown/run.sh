#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L3-001-worker-pool-shutdown"
go build -o "$OUT" main.go
"$OUT"
