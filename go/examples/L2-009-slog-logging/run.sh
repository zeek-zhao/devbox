#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L2-009-slog-logging"
go build -o "$OUT" .
"$OUT"
