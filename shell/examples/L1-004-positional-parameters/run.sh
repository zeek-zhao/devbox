#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L1-004-positional-parameters.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

bash demo.sh
