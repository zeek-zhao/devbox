#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L2-005-go-benchmark"
mkdir -p "$OUT"
go build -o "$OUT/program" .
benchmark_output="$(go test -run '^$' -bench '^BenchmarkTokenize$' -benchtime=1x -count=1 ./...)"
if ! grep -q '^BenchmarkTokenize-' <<<"$benchmark_output"; then
  echo "benchmark-present: false"
  exit 1
fi
printf 'benchmark-present: true\n'
printf 'benchmark-iterations: b.N\n'
