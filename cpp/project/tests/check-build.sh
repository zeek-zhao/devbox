#!/usr/bin/env bash
# L2-012-ci-build-test: clean, project-local automation callable from existing CI.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP="$(mktemp -d "${TMPDIR:-/tmp}/devbox-cpp-build-check-XXXXXX")"
trap 'rm -rf "$TEMP"' EXIT
cmake -S "$ROOT" -B "$TEMP/build" -DCMAKE_BUILD_TYPE=Release >&2
cmake --build "$TEMP/build" -j 4 >&2
ctest --test-dir "$TEMP/build" --output-on-failure >&2
cmake --install "$TEMP/build" --prefix "$TEMP/install" >&2
[[ -x "$TEMP/install/bin/devbox-cpp-project" ]]
[[ -f "$TEMP/install/include/index.h" && -f "$TEMP/install/include/index_c.h" ]]
cmake -S "$ROOT/tests/install-consumer" -B "$TEMP/consumer" \
  -DCMAKE_PREFIX_PATH="$TEMP/install" >&2
cmake --build "$TEMP/consumer" >&2
"$TEMP/consumer/consumer"
(cd "$TEMP/build" && cpack -G TGZ >&2)
