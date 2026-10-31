#!/usr/bin/env bash
set -euo pipefail

BUILD="${TMPDIR:-/tmp}/devbox-cpp-L2-010-dependency-integration"
CXX="${CXX:-g++}"
export CXX

cmake -S . -B "$BUILD" -DDEVBOX_ENABLE_OPTIONAL_LOGGING=OFF > /dev/null
cmake --build "$BUILD" > /dev/null
"$BUILD/dependency_demo"
