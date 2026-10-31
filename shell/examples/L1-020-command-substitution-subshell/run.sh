#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L1-020-command-substitution-subshell.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

bash demo.sh
