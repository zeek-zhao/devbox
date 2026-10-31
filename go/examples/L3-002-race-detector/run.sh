#!/usr/bin/env bash
set -euo pipefail

WORK="${TMPDIR:-/tmp}/devbox-go-L3-002-race-detector"
OUT="$WORK/program"
REPORT="$WORK/race-report.txt"
mkdir -p "$WORK"
go build -race -o "$OUT" main.go
if "$OUT" race >"$REPORT" 2>&1; then
  echo "race-detector-missed: true"
  exit 1
elif grep -q 'WARNING: DATA RACE' "$REPORT"; then
  "$OUT"
else
  echo "race-detector-report-invalid: true"
  exit 1
fi
