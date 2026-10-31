#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
IMAGE="ghcr.io/zeek-zhao/devbox-runtime:${TAG:-latest}"
if [[ ! -f "$ROOT/build/build-stamp.txt" ]]; then "$ROOT/build.sh"; fi
if ! docker image inspect "$IMAGE" >/dev/null; then
  printf '[skip] devbox-runtime 不在本地\n'
  exit 0
fi
actual_file="$(mktemp)"
expected_file="$(mktemp)"
trap 'rm -f -- "$actual_file" "$expected_file"' EXIT
docker run --rm -v "$ROOT:/app:ro" "$IMAGE" bash /app/src/main.sh --self-check >"$actual_file"
cat >"$expected_file" <<'EXPECTED'
deploy	created
deploy	unchanged
CHECK        STATUS
files        PASS
integrity    PASS
layout       PASS
TOTAL 3 PASS 3 FAIL 0
checks=3
self-check OK
EXPECTED
if ! cmp -s -- "$expected_file" "$actual_file"; then
  printf '[fail] shell runtime 输出不匹配\n期望:\n' >&2
  cat "$expected_file" >&2
  printf '实际:\n' >&2
  cat "$actual_file" >&2
  exit 1
fi
printf '[pass] shell runtime OK\n'
