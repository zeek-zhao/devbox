#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L2-018-worker-pool-wait-n.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

bash demo.sh >"$WORK/out"
cat "$WORK/out"
[[ "$(cat "$WORK/out")" == 'pool=workers6 ok=5 failed=1' ]]
