#!/usr/bin/env bash
set -euo pipefail
export GOFLAGS="-mod=mod -buildvcs=false"
export GOPROXY=off GOSUMDB=off GOTOOLCHAIN=local GOWORK=off
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

if [[ "$#" -gt 1 || ( "$#" == 1 && "$1" != "--integration" && "$1" != "--compile-integration" ) ]]; then
  echo '[fail] usage: test.sh [--integration]' >&2
  exit 2
fi
if ! command -v go >/dev/null; then
  ARGS=()
  if [[ "${1:-}" == "--integration" ]]; then
    ARGS=(--compile-integration)
  fi
  docker run --rm --network none --user "$(id -u):$(id -g)" \
    -e HOME=/tmp -v "$ROOT:/work" -w /work \
    "ghcr.io/zeek-zhao/devbox-go:${TAG:-latest}" bash ./test.sh "${ARGS[@]}"
  if [[ "${1:-}" == "--integration" ]]; then
    ./build/gateway-integration.test -test.run '^TestTCP' -test.timeout=60s
  fi
  exit 0
fi

bash ./build.sh
# L3-002-race-detector: concurrent admission, counters and shutdown run under instrumentation.
if ! CGO_ENABLED=1 go test -race -count=1 -timeout=60s ./... >build/race.txt 2>&1; then
  cat build/race.txt >&2
  exit 1
fi
go test -run '^$' -bench '^BenchmarkProcess$' -benchtime=500ms \
  -cpuprofile=build/cpu.pprof -o build/gateway.test ./internal/gateway >build/benchmark.txt
go tool pprof -top build/gateway.test build/cpu.pprof >build/profile.txt
if ! grep -q 'gateway.*Process' build/profile.txt; then
  echo '[fail] CPU profile contains no gateway processing samples' >&2
  exit 1
fi
# L2-007-cross-compilation: compile a static foreign-architecture binary without executing it.
CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -trimpath -o build/devbox-go-project-arm64 ./src
if [[ "${1:-}" == "--integration" ]]; then
  if ! go test -tags=integration -run '^TestTCP' -count=1 -timeout=60s ./... >build/integration.txt 2>&1; then
    cat build/integration.txt >&2
    exit 1
  fi
elif [[ "${1:-}" == "--compile-integration" ]]; then
  CGO_ENABLED=0 go test -c -tags=integration -o build/gateway-integration.test ./internal/gateway
fi
echo '[pass] go project tests OK'
