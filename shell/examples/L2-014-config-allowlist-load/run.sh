#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L2-014-config-allowlist-load.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

cp config.txt "$WORK/config.txt"
bash demo.sh "$WORK/config.txt" >"$WORK/out"
cat "$WORK/out"
[[ "$(cat "$WORK/out")" == 'config=loaded keys=3 rejected=root_shell' ]]
