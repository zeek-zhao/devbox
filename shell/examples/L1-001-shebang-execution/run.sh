#!/usr/bin/env bash
set -euo pipefail

# 直接执行依赖文件的执行位。git 只记录 100644/100755 两种模式，一旦克隆到不保留
# 权限位的文件系统（例如 Windows 挂载卷），脚本会退化成 644，此时 ./demo.sh 直接
# 报 Permission denied。这里显式补齐，保证本用例测的是「shebang 如何选择解释器」，
# 而不是宿主文件系统的权限传播。
[ -x ./demo.sh ] || chmod +x ./demo.sh

./demo.sh
