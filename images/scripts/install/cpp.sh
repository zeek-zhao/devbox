#!/usr/bin/env bash
# ==================================================================
# C / C++ 工具链安装（唯一真本：cpp 镜像与 all 镜像都调这一个脚本）
# ==================================================================
set -euo pipefail

: "${GCC_MAJOR:?需要 GCC_MAJOR}"
: "${CLANG_MAJOR:?需要 CLANG_MAJOR}"
: "${CMAKE_MIN_VERSION:?需要 CMAKE_MIN_VERSION}"

echo "==> 安装 C/C++ 工具链 gcc-${GCC_MAJOR} / clang-${CLANG_MAJOR}"
apt-get update
apt-get install -y --no-install-recommends \
  "gcc-${GCC_MAJOR}" "g++-${GCC_MAJOR}" \
  "clang-${CLANG_MAJOR}" "lld-${CLANG_MAJOR}" \
  cmake ninja-build ccache \
  gcovr lcov \
  libgtest-dev libgmock-dev libbenchmark-dev \
  cppcheck \
  libssl-dev zlib1g-dev

cmake_version="$(cmake --version | awk 'NR == 1 {print $3}')"
if [ "$(printf '%s\n' "$CMAKE_MIN_VERSION" "$cmake_version" | sort -V | head -n1)" != "$CMAKE_MIN_VERSION" ]; then
  echo "cmake 实测版本 ${cmake_version} 低于要求版本 ${CMAKE_MIN_VERSION}" >&2
  exit 1
fi

# 默认编译器指向锁定的版本（Ubuntu 默认是 13，这里强制升到 14）
for pair in "gcc:${GCC_MAJOR}" "g++:${GCC_MAJOR}" "gcc-ar:${GCC_MAJOR}" "gcc-nm:${GCC_MAJOR}" "gcc-ranlib:${GCC_MAJOR}"; do
  name="${pair%%:*}"
  major="${pair##*:}"
  if [ -x "/usr/bin/${name}-${major}" ]; then
    update-alternatives --install "/usr/bin/${name}" "${name}" "/usr/bin/${name}-${major}" 100
  fi
done

# clang 家族同样走 alternatives，保证 `clang` / `clang++` 指向锁定版本
for name in clang clang++ clangd lld; do
  if [ -x "/usr/bin/${name}-${CLANG_MAJOR}" ]; then
    update-alternatives --install "/usr/bin/${name}" "${name}" "/usr/bin/${name}-${CLANG_MAJOR}" 100
  fi
done

apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

echo "==> 自检"
gcc --version | head -1
g++ --version | head -1
clang --version | head -1
cmake --version | head -1
ninja --version
cppcheck --version | head -1
# gtest 在 24.04 只有源码，头文件必须存在（用例用 FetchContent 或直接编译源码）
test -d /usr/include/gtest && echo "gtest headers OK"
