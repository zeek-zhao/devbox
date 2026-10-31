#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L1-001-shebang-execution.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

./demo.sh
