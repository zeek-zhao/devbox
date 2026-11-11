#!/usr/bin/env bash
# E 类示例契约校验（M12-CI-01，issue #337；非门禁脚本）
#
# 校验各轨 <lang>/examples/ 下 E-0xx-* 错误处理示例目录满足以下契约：
#   1) 每轨 ≥ 15 个 E 类目录，且类别覆盖 E-001..E-015；
#   2) 目录命名（E-0xx-<slug>）轨内唯一——命名空间按轨道归属（同 docs/76 的 lab 编号纪律：
#      各轨道独立命名空间；跨轨同名主题 slug 如 E-001-error-taxonomy 是「同主题分轨落地」的既定设计）；
#   3) 每个目录含 run.sh，存在且非空（可被 `bash run.sh` 执行）。
#      不强制 +x 位：实测仓库内 db 全轨及部分语言轨 run.sh 为 100644，
#      调用契约 scripts/run-example.sh 以 `bash run.sh` 执行、不依赖可执行位；
#      强制 755 会让 60+ 个存量目录集体变红，属轨道级迁移，不在本卡范围。
#   4) README.md 含非空 `coverage: exempt <理由>` 声明（Q6 拍板：E 例不接入毕业项目，理由必填）。
#
# 零依赖：bash + coreutils（find/grep/sort）。
# 输出为纯文本，OK/FAIL 前缀，可直接粘进 CI job summary。
# 退出码：0 = 全部通过；1 = 契约校验失败；2 = 用法错误。
#
# 用法：
#   bash scripts/check-error-examples.sh                 # 全轨（9 轨）
#   bash scripts/check-error-examples.sh --lang go       # 单轨
set -u

ALL_TRACKS="c cpp go java python rust shell vue db"
MIN_COUNT=15
CATEGORIES="001 002 003 004 005 006 007 008 009 010 011 012 013 014 015"

usage() {
  echo "用法: $0 [--lang <lang>]   lang 可选: $ALL_TRACKS" >&2
  exit 2
}

tracks=""
if [ $# -eq 0 ]; then
  tracks="$ALL_TRACKS"
elif [ $# -eq 2 ] && [ "$1" = "--lang" ]; then
  ok=""
  for t in $ALL_TRACKS; do [ "$2" = "$t" ] && { ok=1; break; }; done
  [ -z "$ok" ] && usage
  tracks="$2"
else
  usage
fi

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
total=0

for t in $tracks; do
  dir="$repo_root/$t/examples"
  if [ ! -d "$dir" ]; then
    echo "FAIL $t: 示例目录不存在: $dir"
    fail=1
    continue
  fi

  mapfile -t edirs < <(find "$dir" -maxdepth 1 -type d -name 'E-[0-9][0-9][0-9]-*' | sort)
  count=${#edirs[@]}
  total=$((total + count))

  if [ "$count" -lt "$MIN_COUNT" ]; then
    echo "FAIL $t: E 类目录数 $count < $MIN_COUNT"
    fail=1
  fi

  # 类别覆盖：E-001..E-015 每类至少一个目录
  missing=""
  for c in $CATEGORIES; do
    found=""
    for d in "${edirs[@]}"; do
      base="$(basename "$d")"
      num="${base#E-}"
      [ "${num:0:3}" = "$c" ] && { found=1; break; }
    done
    [ -z "$found" ] && missing="$missing E-$c"
  done
  if [ -n "$missing" ]; then
    echo "FAIL $t: 类别覆盖缺失:$missing"
    fail=1
  fi

  # 轨内命名唯一（同名目录在同一父目录下不可能，防御 find 异常输出）
  declare -A seen_in_track=()
  for d in "${edirs[@]}"; do
    base="$(basename "$d")"
    if [ -n "${seen_in_track[$base]:-}" ]; then
      echo "FAIL $t: 命名重复: $base"
      fail=1
    fi
    seen_in_track[$base]=1

    if [ ! -f "$d/run.sh" ]; then
      echo "FAIL $t/$base: run.sh 不存在"
      fail=1
    elif [ ! -s "$d/run.sh" ]; then
      echo "FAIL $t/$base: run.sh 为空文件"
      fail=1
    fi
    if [ ! -f "$d/README.md" ]; then
      echo "FAIL $t/$base: README.md 不存在"
      fail=1
    elif ! grep -Eq 'coverage:[[:space:]]*exempt[[:space:]]+[^[:space:]]' "$d/README.md"; then
      echo "FAIL $t/$base: README.md 缺少非空 coverage: exempt 理由"
      fail=1
    fi
  done

  if [ "$fail" -eq 0 ]; then
    echo "OK $t: E 类 $count 个，类别 E-001..E-015 覆盖完整"
  else
    echo "-- $t: E 类 $count 个（存在问题，见上）"
  fi
  unset seen_in_track
done

if [ "$fail" -ne 0 ]; then
  echo "E 类示例契约校验：失败"
  exit 1
fi
echo "E 类示例契约校验通过（轨: $tracks；E 类合计 $total，每轨 ≥ $MIN_COUNT）"
exit 0
