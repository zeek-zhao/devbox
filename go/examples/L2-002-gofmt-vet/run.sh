#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L2-002-gofmt-vet"
mkdir -p "$OUT/source"
cp go.mod *.go "$OUT/source/"
cd "$OUT/source"
unformatted="$(gofmt -l *.go)"
if [ -z "$unformatted" ]; then
  echo "gofmt-detected-unformatted: false"
  exit 1
fi
printf 'gofmt-detected-unformatted: true\n'
gofmt -w *.go
remaining="$(gofmt -l *.go)"
if [ -n "$remaining" ]; then
  echo "gofmt-clean: false"
  exit 1
fi
printf 'gofmt-clean: true\n'
if ! go vet ./...; then
  echo "go-vet: failed"
  exit 1
fi
printf 'go-vet: passed\n'
if ! go test ./... >/dev/null; then
  echo "go-test: failed"
  exit 1
fi
printf 'go-test: passed\n'
go build -o "$OUT/program" .
"$OUT/program"
