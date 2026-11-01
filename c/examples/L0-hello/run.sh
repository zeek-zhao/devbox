#!/usr/bin/env bash
# 用例 hello —— 验证 C 能按 C17 编译并运行
#
# C 没有自己的镜像层：它和 C++ 共用同一套工具链（gcc / g++ / clang 都来自
# images/scripts/install/cpp.sh），语言到镜像的映射见 images/lang-images.tsv。
#
# -std=c17 -Wall -Wextra -Werror 三个一起用是刻意的：C 的很多坑
# （隐式函数声明、有符号/无符号比较、未使用参数）只有开了警告才会暴露，
# 而只有 -Werror 才能保证它们真的被当回事。
set -euo pipefail

CC="${CC:-gcc}"
OUT="${TMPDIR:-/tmp}/devbox-hello-c"

"$CC" -std=c17 -O2 -Wall -Wextra -Werror -o "$OUT" hello.c
"$OUT"
