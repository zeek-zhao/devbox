#!/usr/bin/env bash
set -euo pipefail

BUILD="${TMPDIR:-/tmp}/devbox-cpp-L2-012-ci-build-test"
CXX="${CXX:-g++}"
export CXX
rm -rf -- "$BUILD"
cmake -S . -B "$BUILD" > /dev/null
cmake --build "$BUILD" > /dev/null
printf 'clean-build: ok\n'
if ctest --test-dir "$BUILD" --output-on-failure > "$BUILD/ctest.log" 2>&1; then
  printf 'tests: ok\n'
else
  cat "$BUILD/ctest.log" >&2
  exit 1
fi
