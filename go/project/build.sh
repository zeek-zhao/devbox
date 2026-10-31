#!/usr/bin/env bash
set -euo pipefail
export GOFLAGS="-mod=mod -buildvcs=false"
export GOPROXY=off GOSUMDB=off GOTOOLCHAIN=local GOWORK=off
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

if ! command -v go >/dev/null; then
  docker run --rm --network none --user "$(id -u):$(id -g)" \
    -e HOME=/tmp -v "$ROOT:/work" -w /work \
    "ghcr.io/zeek-zhao/devbox-go:${TAG:-latest}" bash ./build.sh
  exit 0
fi

mkdir -p build
# L2-002-gofmt-vet: formatting and vet are gates, not silent source rewrites.
UNFORMATTED="$(gofmt -l src internal)"
if [[ -n "$UNFORMATTED" ]]; then
  printf '[fail] gofmt required:\n%s\n' "$UNFORMATTED" >&2
  exit 1
fi
go vet ./...
# L2-004-test-coverage: persist statement coverage from every package test.
if ! go test -count=1 -timeout=60s -coverprofile=build/coverage.out ./... >build/tests.txt 2>&1; then
  cat build/tests.txt >&2
  exit 1
fi
CGO_ENABLED=0 go build -trimpath -o build/devbox-go-project ./src
./build/devbox-go-project --self-check
