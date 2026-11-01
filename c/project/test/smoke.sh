#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVER="$ROOT/devbox-c-server"
PORT="${DEVBOX_PORT:-18080}"
BODY_FILE="$(mktemp)"
LOG_FILE="$(mktemp)"
SERVER_PID=""

cleanup() {
  if [[ -n "$SERVER_PID" ]] && kill -0 "$SERVER_PID" 2>/dev/null; then
    kill -TERM "$SERVER_PID"
    wait "$SERVER_PID" || true
  fi
  rm -f "$BODY_FILE" "$LOG_FILE"
}
trap cleanup EXIT

DEVBOX_PORT="$PORT" "$SERVER" > /dev/null 2>"$LOG_FILE" &
SERVER_PID=$!

ready=0
for _ in $(seq 1 50); do
  if curl --silent --show-error --fail \
      --output "$BODY_FILE" --write-out '%{http_code}' \
      "http://127.0.0.1:$PORT/health" 2>/dev/null | grep -qx '200'; then
    ready=1
    break
  fi
  if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    cat "$LOG_FILE" >&2
    exit 1
  fi
  sleep 0.1
done

if [[ "$ready" -ne 1 ]] || ! grep -qx 'ok' "$BODY_FILE"; then
  cat "$LOG_FILE" >&2
  echo "server did not return the expected health response" >&2
  exit 1
fi

kill -TERM "$SERVER_PID"
wait "$SERVER_PID"
SERVER_PID=""
grep -qx 'server stopped' "$LOG_FILE"
echo "smoke: GET /health returned 200 and server stopped cleanly"
