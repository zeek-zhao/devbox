#!/usr/bin/env bash
# ==================================================================
# db 轨道的用例运行器
# ------------------------------------------------------------------
# 和根 scripts/run-example.sh 的区别：那个是「一次性容器跑 run.sh，stdout 逐行 diff」，
# 只适用于单语言、无网络、确定输出的场景。db 是多容器有状态服务，所以这里单独一个。
#
# 契约（用例必须满足，否则本脚本会红）：
#   1) examples/<ID>/run.sh 跑在宿主上，自己通过 docker compose exec 进 toolbox
#   2) stdout 必须确定：显式 ORDER BY、不打时间戳、不打耗时
#   3) expected.txt 是 stdout 的唯一真本，diff 不一致即失败
#   4) run.sh 必须幂等：开始前清理自己的命名空间
#
# 用法：
#   db/scripts/run-example.sh db --all
#   db/scripts/run-example.sh db L1-MY-01-create-and-types
#   db/scripts/run-example.sh db --list
#   db/scripts/run-example.sh db <ID> --update   # 人工确认输出正确后再改写 expected.txt
# ==================================================================
set -uo pipefail

DB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DB_ROOT"

MODE=""; UPDATE=0; TIMEOUT="${DB_EXAMPLE_TIMEOUT:-180}"
POS=()
for a in "$@"; do
  case "$a" in
    --all) MODE="all" ;;
    --list) MODE="list" ;;
    --update) UPDATE=1 ;;
    -*) echo "未知选项: $a" >&2; exit 2 ;;
    *) POS+=("$a") ;;
  esac
done

# 兼容 `run-example.sh db <ID>` 的写法：第一个位置参数如果是轨道名 db，就丢掉。
# 保留这个位置参数是为了和根 scripts/run-example.sh 的调用形态一致，少一个记忆负担。
if [ "${#POS[@]}" -gt 0 ] && [ "${POS[0]}" = "db" ]; then
  POS=("${POS[@]:1}")
fi
ID="${POS[0]:-}"
if [ "${#POS[@]}" -gt 1 ]; then echo "多余的参数: ${POS[1]}" >&2; exit 2; fi

ex_dir="$DB_ROOT/examples"
[ -d "$ex_dir" ] || { echo "找不到 $ex_dir" >&2; exit 2; }

list_all() { find "$ex_dir" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort; }

norm() { sed -e 's/[[:space:]]*$//' "$1" | sed -e '/./,$!d' | tac | sed -e '/./,$!d' | tac; }

run_one() {
  local id="$1"
  local dir="$ex_dir/$id"
  [ -d "$dir" ] || { printf '%-32s  MISSING\n' "$id"; return 1; }
  [ -f "$dir/run.sh" ] || { printf '%-32s  NO-RUNNER\n' "$id"; return 1; }

  local out err rc=0 start end dur
  out="$(mktemp)"; err="$(mktemp)"
  start="$(date +%s)"
  # stdin 必须给 /dev/null：用例里的 docker compose exec 会读 stdin，
  # 不重定向就会把调用方（--all 的 process substitution）的数据流吃掉，
  # 表现是「只跑了前 N 个就报告全部通过」——一个极难发现的假绿。
  if ! timeout "$TIMEOUT" bash "$dir/run.sh" >"$out" 2>"$err" < /dev/null; then rc=1; fi
  end="$(date +%s)"; dur=$((end-start))

  if [ "$rc" -ne 0 ]; then
    printf '%-32s  FAIL (exit!=0, %ss)\n' "$id" "$dur"
    sed 's/^/      | /' "$err" | head -20
    rm -f "$out" "$err"; return 1
  fi

  local expected="$dir/expected.txt"
  if [ "$UPDATE" = "1" ]; then
    cp "$out" "$expected"
    printf '%-32s  UPDATED expected.txt (%ss)\n' "$id" "$dur"
    rm -f "$out" "$err"; return 0
  fi
  if [ ! -f "$expected" ]; then
    printf '%-32s  NO-EXPECTED (%ss)\n' "$id" "$dur"
    rm -f "$out" "$err"; return 1
  fi
  if diff -u <(norm "$expected") <(norm "$out") > /tmp/db-diff.$$ 2>&1; then
    printf '%-32s  PASS (%ss)\n' "$id" "$dur"
    rm -f "$out" "$err" /tmp/db-diff.$$; return 0
  else
    printf '%-32s  MISMATCH (%ss)\n' "$id" "$dur"
    sed 's/^/      /' /tmp/db-diff.$$ | head -30
    rm -f "$out" "$err" /tmp/db-diff.$$; return 1
  fi
}

case "$MODE" in
  list) list_all ;;
  all)
    fail=0; n=0
    while IFS= read -r id; do
      n=$((n+1)); run_one "$id" || fail=$((fail+1))
    done < <(list_all)
    echo "----------------------------------------"
    total="$(list_all | grep -c '' || true)"
    echo "共 $n 个，失败 $fail 个（目录总数 $total）"
    # 回归守卫：跑过的数量必须等于目录总数。
    # 少了就是有东西吃掉了输入流，此时「失败 0」是假绿，必须当失败处理。
    if [ "$n" -ne "$total" ]; then
      echo "ERROR: 只跑了 $n 个，目录里有 $total 个 —— 有命令吃掉了输入流，结果不可信" >&2
      exit 1
    fi
    [ "$fail" -eq 0 ] || exit 1
    ;;
  "")
    [ -n "$ID" ] || { echo "用法: run-example.sh db <ID>|--all|--list" >&2; exit 2; }
    run_one "$ID"
    ;;
esac
