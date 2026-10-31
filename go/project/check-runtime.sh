#!/usr/bin/env bash
set -euo pipefail
export GOFLAGS="-mod=mod -buildvcs=false"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARY="$ROOT/build/devbox-go-project"
IMAGE="ghcr.io/zeek-zhao/devbox-runtime:${TAG:-latest}"

if [[ ! -x "$BINARY" ]]; then
  bash "$ROOT/build.sh"
fi
if ! docker image inspect "$IMAGE" >/dev/null; then
  echo '[skip] devbox-runtime 不在本地'
  exit 0
fi

EXPECTED='health=200 ok
submit=200 {"id":1,"status":"completed","total":3,"words":[{"word":"alpha","count":2},{"word":"beta","count":1}]}
submit=200 {"id":2,"status":"completed","total":2,"words":[{"word":"世界","count":1},{"word":"你好","count":1}]}
limited=429
refilled=200 checkpoint=3/1
invalid=400
closed=503 health=503
# HELP gateway_tasks_total Tasks by lifecycle state.
# TYPE gateway_tasks_total counter
gateway_tasks_total{state="accepted"} 3
gateway_tasks_total{state="completed"} 3
gateway_tasks_total{state="failed"} 0
gateway_tasks_total{state="rejected"} 3
self-check OK'
# The sentinel preserves trailing newlines through command substitution.
if ! ACTUAL="$(docker run --rm --network none -v "$BINARY:/app:ro" "$IMAGE" /app --self-check && printf '.')" ; then
  echo '[fail] go runtime execution failed' >&2
  exit 1
fi
EXPECTED="${EXPECTED}"$'\n.'
if [[ "$ACTUAL" != "$EXPECTED" ]]; then
  printf '[fail] go runtime 输出不匹配\n期望:\n%s\n实际:\n%s\n' "${EXPECTED%.}" "${ACTUAL%.}" >&2
  exit 1
fi
echo '[pass] go runtime OK'
