#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L2-010-os-exec"
go build -o "$OUT" .
"$OUT"
