#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARTIFACT="$ROOT/build/app.jar"
IMAGE="ghcr.io/zeek-zhao/devbox-runtime:${TAG:-latest}"
if [[ ! -f "$ARTIFACT" ]]; then
  bash "$ROOT/build.sh"
fi
if ! docker image inspect "$IMAGE" >/dev/null; then
  echo '[skip] devbox-runtime 不在本地'
  exit 0
fi

ACTUAL="$(mktemp)"
EXPECTED="$(mktemp)"
trap 'rm -f "$ACTUAL" "$EXPECTED"' EXIT
docker run --rm -v "$ARTIFACT:/app.jar:ro" "$IMAGE" \
  java -jar /app.jar --self-check >"$ACTUAL"
cat >"$EXPECTED" <<'EOF'
GET /healthz -> 200 {"status":"ok"}
POST /items -> 201 {"id":1,"name":"Ada \"Q\""}
GET /items/1 -> 200 {"id":1,"name":"Ada \"Q\""}
PUT /items/1 -> 200 {"id":1,"name":"Grace"}
POST /items -> 400 {"error":"name must be 1..64 letters, digits or safe punctuation"}
GET /items -> 200 [{"id":1,"name":"Grace"}]
DELETE /items/1 -> 204
GET /items/1 -> 404 {"error":"item not found"}
GET /missing -> 404 {"error":"route not found"}
GET /metrics -> 200 requests_total 10
[pass] java self-check OK
EOF
if ! cmp -s "$EXPECTED" "$ACTUAL"; then
  printf '[fail] runtime 输出不匹配\n期望:\n' >&2
  cat "$EXPECTED" >&2
  printf '实际:\n' >&2
  cat "$ACTUAL" >&2
  exit 1
fi
echo '[pass] java runtime OK'
