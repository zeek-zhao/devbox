#!/usr/bin/env bash
set -euo pipefail

BINARY="$1"
TEMP="$(mktemp -d "${TMPDIR:-/tmp}/devbox-project-cli-XXXXXX")"
trap 'rm -rf "$TEMP"' EXIT
printf 'alpha beta\ngamma alpha\ndelta\n' >"$TEMP/input"
EXPECTED=$'1: alpha beta\n2: gamma alpha'
[[ "$("$BINARY" "$TEMP/input" ALPHA)" == "$EXPECTED" ]]
[[ "$("$BINARY" --workers 4 "$TEMP/input" alpha)" == "$EXPECTED" ]]
[[ "$("$BINARY" "$TEMP/input" missing)" == NO_MATCH ]]
[[ "$("$BINARY" "$TEMP/input" 'alpha!')" == NO_MATCH ]]
[[ "$("$BINARY" --expr "$TEMP/input" 'alpha AND beta')" == '1: alpha beta' ]]
"$BINARY" --help | grep -q '^usage:'

expect_error() {
  local expected_rc="$1"
  shift
  local rc=0
  "$BINARY" "$@" >"$TEMP/out" 2>"$TEMP/err" || rc=$?
  [[ "$rc" == "$expected_rc" && ! -s "$TEMP/out" && -s "$TEMP/err" ]]
}
expect_error 2
expect_error 2 --unknown
expect_error 2 --workers 2x "$TEMP/input" alpha
expect_error 2 --workers 0 "$TEMP/input" alpha
expect_error 2 --expr "$TEMP/input" 'alpha AND'
expect_error 1 "$TEMP/missing" alpha
grep -q "$TEMP/missing" "$TEMP/err"
