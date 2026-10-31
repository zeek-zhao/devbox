#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L2-004-test-coverage"
mkdir -p "$OUT"
go build -o "$OUT/program" .
if ! go test -coverprofile="$OUT/coverage.out" ./... >/dev/null; then
  echo "go-test-coverage: failed"
  exit 1
fi
go tool cover -func="$OUT/coverage.out" \
  | awk '$2 == "findValue" { print "findValue coverage: " $3; found = 1 } END { if (!found) exit 1 }'
