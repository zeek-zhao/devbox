#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L2-001-local-module-replace"
mkdir -p "$OUT"
go build -o "$OUT/program" .
if ! go test ./... >/dev/null; then
  echo "indexer-test-failed: true"
  exit 1
fi
if ! (cd localparser && go test ./... >/dev/null); then
  echo "localparser-test-failed: true"
  exit 1
fi
"$OUT/program"
