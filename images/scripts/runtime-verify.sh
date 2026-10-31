#!/usr/bin/env bash
# ==================================================================
# runtime 镜像自检：确认「没有编译器也能跑」这件事真的成立
# 由 runtime/Dockerfile 在构建末尾执行，也可以容器里手动跑
# ==================================================================
set -euo pipefail

echo "==> runtime 自检"

fail=0

check() {
  local name="$1"; shift
  if "$@" >/dev/null 2>&1; then
    printf '  [ OK ] %s\n' "$name"
  else
    printf '  [FAIL] %s\n' "$name" >&2
    fail=1
  fi
}

# 动态链接的 C++ 程序必须能起来（libstdc++6 在不在）
cat > /tmp/probe.cpp.txt <<'EOF'
EOF

check "libstdc++6" bash -c 'ldconfig -p | grep -q "libstdc++.so.6"'
check "libgcc_s"   bash -c 'ldconfig -p | grep -q "libgcc_s.so.1"'
check "python3"    python3 -c 'print(1)'
check "java"       java -version

# 必须有编译器这个"不存在"也算通过：runtime 里不该有 cc
if command -v gcc >/dev/null 2>&1; then
  echo "  [WARN] runtime 镜像里存在 gcc，说明层混入了编译器" >&2
fi

rm -f /tmp/probe.cpp.txt

if [ "$fail" -ne 0 ]; then
  echo "==> runtime 自检失败" >&2
  exit 1
fi
echo "==> runtime 自检通过"
