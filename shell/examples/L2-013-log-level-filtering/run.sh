#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L2-013-log-level-filtering.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

LOG_LEVEL=info bash demo.sh >"$WORK/info.log"
LOG_LEVEL=debug bash demo.sh >"$WORK/debug.log"

[[ "$(grep -c 'debug:' "$WORK/info.log")" -eq 0 ]]
grep -q 'debug: debug line' "$WORK/debug.log"
grep -q 'error: error line' "$WORK/info.log"
grep -q 'error: error line' "$WORK/debug.log"
printf 'levels=info-hides-debug error-always-shown\n'
