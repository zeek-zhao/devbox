#!/usr/bin/env bash
# ==================================================================
# 合并前总闸（pre-merge gate）
# ------------------------------------------------------------------
# 为什么需要它：这个仓库的合并是**本地 squash**，一次可能合并十几个分支
# （见 docs/02-流水线.md）。逐个推上去让 CI 逐个红，再逐个修，是最慢的路径。
# 总闸把这批分支在本地一次性合并、一次性跑全量，绿了才推 main。
#
# 它跑的东西与 CI 等价（608 例 + 8 门格式 + 覆盖 + 门禁比对），
# 区别只在「先合并再验」还是「验完再合并」。
#
# 用法：
#   bash scripts/pre-merge.sh --branches feat/a feat/b            # 只演练，不推
#   bash scripts/pre-merge.sh --branches feat/a feat/b --push     # 绿了直接推 main
#   bash scripts/pre-merge.sh --from-file /tmp/plan.txt --push    # 从文件读分支名
#
# 常用选项：
#   --base REF              基线（默认 origin/main）
#   --push                  全部通过后推 origin HEAD:main
#   --keep                  保留临时 worktree（排查用）
#   --skip-examples         跳过用例矩阵（只改文档时快速过一遍）
#   --with-db               连 db 轨道一起跑（改过 db/ 时会自动带上）
#   --allow-gate-change     允许本批分支触碰门禁文件（人工评审后）
#   --auto-resolve          冲突时按「分支是否真改过该文件」自动取边
#
# 判据（任一条不过就 exit 1，且不推）：
#   1) 全量用例（每门 examples/ 下全部）通过
#   2) 每门格式化 --check 达标
#   3) 覆盖表自洽（pending/exempt 明账可数）
#   4) shared 自测 + README 函数索引
#   5) 版本真本 + 文档命令
#   6) 相对 base 未触碰门禁文件（除 --allow-gate-change）
#
# 为什么默认不自动解冲突：
#   本项目踩过一次 —— 冲突自动取「ours」，21 个 PR 全报合并成功、退出码 0，
#   但 77 个 db 用例被静默退回成 8 行骨架，而骨架自己也能跑通。
#   所以默认停下来让人看；--auto-resolve 用的是「分支是否真改过该文件」判据，
#   并且会把每个文件的取边决定逐条打印出来。
# ==================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ORIG="$PWD"
cd "$ROOT"

BASE="${BASE:-origin/main}"
IMAGE_TAG="${IMAGE_TAG:-local}"
PUSH=0
KEEP=0
SKIP_EXAMPLES=0
WITH_DB=0
ALLOW_GATE=0
AUTO_RESOLVE=0
BRANCHES=()
PLAN_FILE=""

die() { echo "ERROR: $*" >&2; exit 2; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --branches)
      shift
      while [ "$#" -gt 0 ] && [ "${1#--}" = "$1" ]; do BRANCHES+=("$1"); shift; done
      ;;
    --from-file) shift; PLAN_FILE="${1:?--from-file 需要文件名}"; shift ;;
    --base)      shift; BASE="${1:?--base 需要 ref}"; shift ;;
    --push)      PUSH=1; shift ;;
    --keep)      KEEP=1; shift ;;
    --skip-examples) SKIP_EXAMPLES=1; shift ;;
    --with-db)   WITH_DB=1; shift ;;
    --allow-gate-change) ALLOW_GATE=1; shift ;;
    --auto-resolve) AUTO_RESOLVE=1; shift ;;
    -h|--help)   sed -n '2,40p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)           die "未知参数: $1" ;;
  esac
done

if [ -n "$PLAN_FILE" ]; then
  [ -f "$PLAN_FILE" ] || die "计划文件不存在: $PLAN_FILE"
  # Windows 侧生成的文件带 CRLF，字段末尾的 \r 会让 git 命令静默失败。
  if grep -q $'\r' "$PLAN_FILE" 2>/dev/null; then
    echo "计划文件含 CRLF，先 tr -d '\\r' 再跑" >&2
    tr -d '\r' < "$PLAN_FILE" > "$PLAN_FILE.tmp" && mv "$PLAN_FILE.tmp" "$PLAN_FILE"
    echo "已就地剥掉 CR" >&2
  fi
  while IFS= read -r line; do
    line="${line%%#*}"
    line="$(printf '%s' "$line" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"
    [ -n "$line" ] && BRANCHES+=("$line")
  done < "$PLAN_FILE"
fi

[ "${#BRANCHES[@]}" -gt 0 ] || die "没有待合分支（--branches 或 --from-file）"

git rev-parse --verify -q "$BASE^{commit}" >/dev/null || die "基线 ref 无效：$BASE（先 git fetch origin）"

# ------------------------------------------------------------------
# 1) 建临时 worktree
# ------------------------------------------------------------------
STAMP="$(date +%Y%m%d-%H%M%S)"
WT="${TMPDIR:-/tmp}/devbox-premerge-$STAMP"
BR="premerge/$STAMP"

cleanup() {
  local rc=$?
  cd "$ORIG" 2>/dev/null || true
  if [ -d "$WT" ]; then
    if [ "$KEEP" -eq 1 ]; then
      echo "保留临时 worktree：$WT（分支 $BR）" >&2
    else
      # 顺序不能反：分支被 worktree 占用时 git branch -D 会静默失败
      git -C "$ROOT" worktree remove --force "$WT" >/dev/null 2>&1 || true
      git -C "$ROOT" branch -D "$BR" >/dev/null 2>&1 || true
    fi
  fi
  exit "$rc"
}
trap cleanup EXIT

git -C "$ROOT" worktree add -b "$BR" "$WT" "$BASE" >/dev/null
echo "临时 worktree：$WT（分支 $BR，基线 $BASE）"

# ------------------------------------------------------------------
# 2) 依次 squash 合并
# ------------------------------------------------------------------
echo
echo "==================== 合并 ${#BRANCHES[@]} 个分支 ===================="
IDENT=(-c user.name=zeek.zhao -c user.email=zeek.zhao@foxmail.com)

for b in "${BRANCHES[@]}"; do
  git -C "$WT" rev-parse --verify -q "$b^{commit}" >/dev/null || die "分支不存在：$b"

  echo "--> $b"
  if git -C "$WT" merge --squash "$b" >/dev/null 2>&1; then
    :
  else
    mapfile -t conflicted < <(git -C "$WT" diff --name-only --diff-filter=U)
    echo "    冲突 ${#conflicted[@]} 个文件：" >&2
    printf '      %s\n' "${conflicted[@]}" >&2

    if [ "$AUTO_RESOLVE" -ne 1 ]; then
      echo >&2
      echo "默认不自动解冲突。请在 $WT 里手动解决后重跑，或加 --auto-resolve：" >&2
      echo "  cd $WT && git status" >&2
      echo "  （保留现场）" >&2
      KEEP=1
      exit 2
    fi

    # 「分支是否真改过该文件」判据 —— 真改过就取分支，否则取当前树。
    # 三条防线缺一不可（本项目踩过：判据失效时全部取 ours，静默丢内容）。
    changed="$(git -C "$WT" diff --name-only "$BASE...$b")"
    if [ -z "$changed" ]; then
      echo "    ERROR: $BASE...$b 差异为空，判据不可信，拒绝自动解冲突" >&2
      KEEP=1
      exit 2
    fi
    for f in "${conflicted[@]}"; do
      # 用 here-string 喂 grep，不要用管道：管道里的 grep -q 会提前退出，
      # 上游吃 SIGPIPE，配合 pipefail 就把「命中」判成「未命中」。
      if grep -qxF -- "$f" <<< "$changed"; then
        git -C "$WT" checkout --theirs -- "$f"
        echo "      theirs  $f"
      else
        git -C "$WT" checkout --ours -- "$f"
        echo "      ours    $f"
      fi
      git -C "$WT" add -- "$f"
    done

    # 解完立刻查冲突标记：取错边时通常就是整块标记留下了
    # 不要写成 `grep -l ... | grep -q .`：管道里的 grep -q 会提前退出，
    # 上游吃 SIGPIPE，配合 pipefail 会把「命中」判成「未命中」。
    markers="$(grep -lE '^(<<<<<<<|>>>>>>>) ' "${conflicted[@]}" 2>/dev/null || true)"
    if [ -n "$markers" ]; then
      echo "    ERROR: 仍有冲突标记，停止：" >&2
      printf '      %s\n' $markers >&2
      KEEP=1
      exit 2
    fi
  fi

  # 分支内容已在树里（比如重复传入）时 merge --squash 不会留下任何暂存改动，
  # 这时 commit 会报「nothing to commit」并把整个流程打断。
  if git -C "$WT" diff --cached --quiet; then
    echo "    无新增改动，跳过提交"
    continue
  fi

  msg="$(git -C "$WT" log -1 --format=%s "$b")"
  git -C "$WT" "${IDENT[@]}" commit -q \
    -m "$msg" \
    -m "pre-merge: 从 $b 本地 squash 合并（PR 阶段不跑 CI，合并后由 fast 档守门）"
  echo "    已提交：$(git -C "$WT" log -1 --format='%h %s')"
done

echo
echo "合并后相对 $BASE 的改动："
git -C "$WT" diff --stat "$BASE"..HEAD | tail -20

# ------------------------------------------------------------------
# 3) 校验
# ------------------------------------------------------------------
FAILED=()

step() {
  local name="$1"; shift
  echo
  echo "==================== $name ===================="
  if "$@"; then
    echo "[OK] $name"
  else
    echo "[FAIL] $name" >&2
    FAILED+=("$name")
  fi
}

# 门禁文件比对：触碰了就不许自动合并
if [ "$ALLOW_GATE" -eq 1 ]; then
  echo
  echo "==================== 门禁文件（已豁免） ===================="
  bash "$WT/scripts/check-gate-files.sh" "$BASE" || true
  echo "[WARN] 本次显式允许触碰门禁文件，请确认提交信息里写明了为什么改"
else
  step "门禁文件未被动" bash "$WT/scripts/check-gate-files.sh" "$BASE"
fi

step "版本真本自洽" bash "$WT/scripts/check-version-truth.sh"
step "文档命令校验" bash "$WT/scripts/check-docs.sh"
step "覆盖表自洽"   bash "$WT/scripts/coverage-check.sh"
step "shared 索引"  bash "$WT/scripts/check-shared-index.sh"
step "shared 自测"  env TAG="$IMAGE_TAG" bash "$WT/shared/tests/run.sh"

echo
echo "==================== 格式化（8 门） ===================="
if TAG="$IMAGE_TAG" bash "$WT/scripts/fmt.sh" --check; then
  echo "[OK] 格式化"
else
  echo "[FAIL] 格式化" >&2
  FAILED+=("格式化")
fi

if [ "$SKIP_EXAMPLES" -eq 1 ]; then
  echo
  echo "[SKIP] 用例矩阵（--skip-examples）—— 只在只改文档时用"
else
  echo
  echo "==================== 全量用例 ===================="
  mapfile -t LANGS < <(cd "$WT" && for d in */; do d="${d%/}"; [ -d "$d/examples" ] && echo "$d"; done)

  # db 轨道的栈是独占的（compose 项目名固定 devbox-db），
  # 在临时 worktree 里起它会顶掉别的 worktree 正在用的那套，
  # 所以默认只在「本批真的改过 db/」时才跑，其余情况要显式 --with-db。
  db_changed=$(printf '%s\n' "$(git -C "$WT" diff --name-only "$BASE"..HEAD)" | grep -c '^db/' || true)

  for l in "${LANGS[@]}"; do
    if [ "$l" = "db" ] && [ "$WITH_DB" -eq 0 ] && [ "$db_changed" -eq 0 ]; then
      echo "[SKIP] 用例-db（本批没改 db/，且没加 --with-db；db 栈独占，会打断并行卡）"
      continue
    fi
    # 有些轨道不走 run-example.sh：db 的用例要连真库，
    # 由 db/scripts/run-all.sh 自己负责「起 compose → 等就绪 → 跑 → 汇总」。
    # 一律按 run-example.sh 跑会去拉一个不存在的 devbox-db 镜像。
    if [ -f "$WT/$l/scripts/run-all.sh" ]; then
      if bash "$WT/$l/scripts/run-all.sh"; then
        echo "[OK] 用例-$l"
      else
        echo "[FAIL] 用例-$l" >&2
        FAILED+=("用例-$l")
      fi
    elif TAG="$IMAGE_TAG" bash "$WT/scripts/run-example.sh" "$l" --all; then
      echo "[OK] 用例-$l"
    else
      echo "[FAIL] 用例-$l" >&2
      FAILED+=("用例-$l")
    fi
  done
fi

# ------------------------------------------------------------------
# 4) 收口
# ------------------------------------------------------------------
echo
echo "------------------------------------------------------------------"
if [ "${#FAILED[@]}" -gt 0 ]; then
  echo "合并前校验失败 ${#FAILED[@]} 项：" >&2
  printf '  %s\n' "${FAILED[@]}" >&2
  echo "临时 worktree 与分支已保留：$WT（$BR）" >&2
  KEEP=1
  exit 1
fi

echo "合并前校验全部通过。"
echo "提交列表（$BASE..HEAD）："
git -C "$WT" log --oneline "$BASE"..HEAD

if [ "$PUSH" -eq 1 ]; then
  echo
  echo "推送到 origin/main ..."
  # .githooks/pre-push 会拒绝直推 main，这里显式授权：
  # 能走到这一步说明全量校验已经过了，正是那道钩子留的例外场景。
  DEVBOX_ALLOW_MAIN_PUSH=1 git -C "$WT" push origin "HEAD:main"
  echo "已推送。fast 档流水线会在 main 上跑一遍（约 90 秒）。"
  echo "要验发布档：git tag v\$(cat VERSION) && git push origin v\$(cat VERSION)"
else
  echo
  echo "（演练模式，未推送。加 --push 才会推 origin/main）"
  echo "确认无误后："
  echo "  bash scripts/pre-merge.sh --branches ${BRANCHES[*]} --push"
fi

exit 0
