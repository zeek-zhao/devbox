#!/usr/bin/env bash
set -euo pipefail

CXX="${CXX:-g++}"
BUILD="${TMPDIR:-/tmp}/devbox-cpp-L2-002-cmake-targets-build"
cmake -S . -B "$BUILD" -DCMAKE_CXX_COMPILER="$CXX" >&2
cmake --build "$BUILD" >&2
cmake --install "$BUILD" --prefix "$BUILD/install" >&2

test -f "$BUILD/install/bin/cmake-targets"
test -f "$BUILD/install/include/message.hpp"
"$BUILD/install/bin/cmake-targets"
