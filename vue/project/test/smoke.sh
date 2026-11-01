#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
port="${PORT:-18081}"
tmp="$(mktemp)"
PORT="$port" node "$project_root/src/server.js" >"$tmp" 2>&1 &
server_pid=$!
cleanup() {
  kill -TERM "$server_pid" 2>/dev/null || true
  wait "$server_pid" 2>/dev/null || true
  rm -f "$tmp" "$tmp.html"
}
trap cleanup EXIT

attempt=0
while ! curl --silent --fail "http://127.0.0.1:$port/" -o "$tmp.html"; do
  attempt=$((attempt + 1))
  if [ "$attempt" -ge 30 ]; then
    cat "$tmp" >&2
    echo "SSR server did not become ready on port $port" >&2
    exit 1
  fi
  sleep 0.2
done

# L2-004-unit-test-harness: this smoke check asserts the actual SSR response and exits on failure.
if ! grep -q 'class="todo-item"' "$tmp.html" ||
  ! grep -q 'Learn Vue SSR' "$tmp.html"; then
  cat "$tmp.html" >&2
  echo "SSR response did not contain the seeded todo" >&2
  exit 1
fi

printf 'SSR smoke passed on port %s (todo-item present)\n' "$port"
rm -f "$tmp.html"
