#!/usr/bin/env bash
# ==================================================================
# 用例 runner —— 全部 330 个用例的唯一入口
# ------------------------------------------------------------------
# 契约（每个用例目录必须满足）：
#   <lang>/examples/<ID>/
#     run.sh       必须存在，自己负责编译与运行，只往 stdout 打业务输出
#     expected.txt 期望输出；规则：逐行精确，忽略行尾空白与首尾空行
#     README.md    考点说明（阶段 2 铺开时强制，阶段 0 的 hello 可省）
#
# 用法：
#   scripts/run-example.sh cpp hello
#   scripts/run-example.sh go --all
#   scripts/run-example.sh rust --list
#   scripts/run-example.sh cpp hello --keep        # 保留容器，便于 docker exec 进去复现
#   scripts/run-example.sh python --all --update   # 用当前输出重写 expected.txt（仅限新写用例时）
# ==================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TAG="${TAG:-${IMAGE_TAG:-local}}"
REGISTRY="${REGISTRY:-$(grep -E '^REGISTRY=' images/versions.env 2>/dev/null | cut -d= -f2 || true)}"
PREFIX="${REGISTRY:+${REGISTRY}/}"

LANG_ARG="${1:-}"; shift || true
MODE="one"
TARGET=""
UPDATE=0
KEEP=0

while [ $# -gt 0 ]; do
  case "$1" in
    --all) MODE="all"; shift ;;
    --list) MODE="list"; shift ;;
    --update) UPDATE=1; shift ;;
    --keep) KEEP=1; shift ;;
    *) TARGET="$1"; shift ;;
  esac
done

if [ -z "$LANG_ARG" ]; then
  echo "用法: scripts/run-example.sh <cpp|go|rust|shell|python|java|all> [<ID>|--all|--list]" >&2
  exit 2
fi

# 容器内挂载路径：Windows(Git Bash) 下 docker 不认 /d/xxx，必须先转成 D:/xxx
host_path() {
  if command -v cygpath >/dev/null 2>&1; then cygpath -w "$1"; else echo "$1"; fi
}

examples_for() {
  local lang="$1"
  find "$lang/examples" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort
}

run_one() {
  local lang="$1" id="$2"
  local dir="$lang/examples/$id"
  local image="${PREFIX}devbox-${lang}:${TAG}"

  if [ ! -d "$dir" ]; then
    printf '%-28s  MISSING(%s)\n' "$lang/$id" "$dir"; return 1
  fi
  if [ ! -f "$dir/run.sh" ]; then
    printf '%-28s  NO-RUNNER\n' "$lang/$id"; return 1
  fi

  local out err rc=0 start end dur
  out="$(mktemp)"; err="$(mktemp)"
  start="$(date +%s)"

  # --keep：保留容器便于进去复现（默认 --rm 一跑完就没了，调试只能靠加 printf）
  local -a run_args=(run)
  local cname="devbox-keep-${lang}-${id}"
  if [ "$KEEP" = "1" ]; then
    docker rm -f "$cname" >/dev/null 2>&1 || true
    run_args+=(--name "$cname")
  else
    run_args+=(--rm)
  fi

  if ! docker "${run_args[@]}" \
        -v "$(host_path "$ROOT"):/work" \
        -w "/work/$dir" \
        -e "DEBIAN_FRONTEND=noninteractive" \
        "$image" bash run.sh >"$out" 2>"$err"; then
    rc=1
  fi
  end="$(date +%s)"; dur=$((end-start))

  if [ "$rc" -ne 0 ]; then
    printf '%-28s  FAIL (exit!=0, %ss)\n' "$lang/$id" "$dur"
    if [ "$KEEP" = "1" ]; then printf '      容器保留：docker exec -it %s bash\n' "$cname"; fi
    sed 's/^/      | /' "$err" | head -20
    rm -f "$out" "$err"; return 1
  fi

  local expected="$dir/expected.txt"
  if [ "$UPDATE" = "1" ]; then
    cp "$out" "$expected"
    printf '%-28s  UPDATED expected.txt (%ss)\n' "$lang/$id" "$dur"
    rm -f "$out" "$err"; return 0
  fi

  if [ ! -f "$expected" ]; then
    printf '%-28s  NO-EXPECTED (%ss)\n' "$lang/$id" "$dur"
    rm -f "$out" "$err"; return 1
  fi

  # 归一化：去行尾空白、去首尾空行
  norm() { sed -e 's/[[:space:]]*$//' "$1" | sed -e '/./,$!d' | tac | sed -e '/./,$!d' | tac; }

  if diff -u <(norm "$expected") <(norm "$out") > /tmp/devbox-diff.$$ 2>&1; then
    printf '%-28s  PASS (%ss)\n' "$lang/$id" "$dur"
    rm -f "$out" "$err" /tmp/devbox-diff.$$; return 0
  else
    printf '%-28s  MISMATCH (%ss)\n' "$lang/$id" "$dur"
    sed 's/^/      /' /tmp/devbox-diff.$$ | head -20
    rm -f "$out" "$err" /tmp/devbox-diff.$$; return 1
  fi
}

langs_to_run() {
  if [ "$LANG_ARG" = "all" ]; then echo "cpp go rust shell python java"; else echo "$LANG_ARG"; fi
}

case "$MODE" in
  list)
    for l in $(langs_to_run); do
      examples_for "$l" | sed "s|^|$l/|"
    done
    ;;
  all)
    total=0; failed=0
    for l in $(langs_to_run); do
      while IFS= read -r id; do
        [ -z "$id" ] && continue
        total=$((total+1))
        run_one "$l" "$id" || failed=$((failed+1))
      done < <(examples_for "$l")
    done
    echo "------------------------------------------------------------------"
    echo "合计 ${total} 个用例，通过 $((total-failed))，失败 ${failed}"
    [ "$failed" -eq 0 ] || exit 1
    ;;
  one)
    if [ -z "$TARGET" ]; then
      echo "--all 或 --list 需要一个语言参数" >&2; exit 2
    fi
    run_one "$LANG_ARG" "$TARGET"
    ;;
esac
