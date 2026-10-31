#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L1-024-stdout-stderr.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

bash demo.sh >"$WORK/stdout" 2>"$WORK/stderr"
[[ "$(<"$WORK/stdout")" == 'result=ready' ]]
[[ "$(<"$WORK/stderr")" == 'diagnostic=checking' ]]
cat "$WORK/stdout"
