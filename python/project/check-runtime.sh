#!/usr/bin/env bash
set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE="ghcr.io/zeek-zhao/devbox-runtime:${TAG:-latest}"

if [[ ! -f "$ROOT/build/build-stamp.txt" ]]; then
  bash "$ROOT/build.sh"
fi
if ! docker image inspect "$IMAGE" >/dev/null; then
  echo "[skip] devbox-runtime 不在本地"
  exit 0
fi

# A file comparison also checks the final newline (command substitution would not).
mkdir -p "$ROOT/build"
docker run --rm --pull=never --network none -e PYTHONDONTWRITEBYTECODE=1 \
  -v "$ROOT:/app:ro" "$IMAGE" \
  python3 /app/src/main.py --self-check > "$ROOT/build/runtime-actual.txt"
cat > "$ROOT/build/runtime-expected.txt" <<'EOF'
clean: 3 rows
date,category,amount
2026-01-01,food,12.50
2026-01-02,books,20.00
2026-01-03,food,0.10
summary:
category | count | total
---------+-------+------
books    | 1     | 20.00
food     | 2     | 12.60
report:
CSV report
category | count | total
---------+-------+------
books    | 1     | 20.00
food     | 2     | 12.60
rows: 3
total: 32.60
EOF
if ! cmp -s "$ROOT/build/runtime-expected.txt" "$ROOT/build/runtime-actual.txt"; then
  printf '[fail] python runtime 输出不匹配\n期望:\n' >&2
  cat "$ROOT/build/runtime-expected.txt" >&2
  printf '实际:\n' >&2
  cat "$ROOT/build/runtime-actual.txt" >&2
  exit 1
fi
echo "[pass] python runtime OK"
