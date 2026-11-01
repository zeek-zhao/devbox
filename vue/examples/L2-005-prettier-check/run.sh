#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="${TMPDIR:-/tmp}/devbox-L2-005-prettier-check"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

printf '%s\n' 'const value="unformatted";console.log(value)' >"$TMP_DIR/sample.js"

set +e
prettier --check "$TMP_DIR/sample.js" >"$TMP_DIR/prettier.log" 2>&1
rc=$?
set -e

case "$rc" in
  1)
    printf '%s\n' 'format differences detected (exit 1)'
    ;;
  2)
    cat "$TMP_DIR/prettier.log" >&2
    exit 2
    ;;
  0)
    echo 'expected formatting differences, but prettier reported none' >&2
    exit 1
    ;;
  *)
    cat "$TMP_DIR/prettier.log" >&2
    exit "$rc"
    ;;
esac
