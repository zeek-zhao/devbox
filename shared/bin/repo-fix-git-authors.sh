#!/usr/bin/env bash
# 批量修正一组 git 仓库的历史 Author（git filter-repo 重写 + 强推）。
#
# 用途：换机器 / 换邮箱之后，把散落各处仓库里的历史提交统一成同一个身份。
#       典型场景是多仓库工作区（repo / 一堆并列 clone）一次性对齐。
#
# 退出码：0 全部成功或无需修改；1 有仓库失败；2 参数或依赖问题

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/log.sh
source "$HERE/../lib/log.sh"

REPO_ROOT="$(pwd)"
TARGET_NAME=""
TARGET_EMAIL=""
DRY_RUN=false
AUTO_YES=false
DO_PUSH=true
KEEP_PATTERNS=("github-actions")
LOG_DIR_OVERRIDE=""

usage() {
  cat <<'USAGE'
用法:
  bash shared/bin/repo-fix-git-authors.sh --repo-root DIR \
       --name "Zeek Zhao" --email zeek.zhao@foxmail.com [选项]

选项:
  --repo-root DIR   要扫描的目录（默认当前目录），递归找 .git
  --name NAME       目标 author/committer 名
  --email MAIL      目标 author/committer 邮箱
  --keep PATTERN    跳过邮箱含此模式的提交（可重复，默认 github-actions）
  --dry-run         只报告，不重写、不推送
  --yes             不交互确认
  --no-push         重写但不推远端
  --log-dir DIR     日志根目录（默认 $TMPDIR/repo-fix-git-authors）
  -h, --help        显示本帮助

安全设计:
  * filter-repo 会删掉 remote，所以先存 remotes 再恢复。
  * 重写前后各存一份 log 快照，比对「日期+标题」，只有 hash 允许变；
    不一致就不推，除非人工再确认一次。
  * 默认每个仓库都要交互确认；--dry-run 下不可能误伤。
USAGE
}

while (($# > 0)); do
  case "$1" in
    --repo-root)
      REPO_ROOT="$2"
      shift 2
      ;;
    --name)
      TARGET_NAME="$2"
      shift 2
      ;;
    --email)
      TARGET_EMAIL="$2"
      shift 2
      ;;
    --keep)
      KEEP_PATTERNS+=("$2")
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --yes)
      AUTO_YES=true
      shift
      ;;
    --no-push)
      DO_PUSH=false
      shift
      ;;
    --log-dir)
      LOG_DIR_OVERRIDE="$2"
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      log_error "未知参数: $1"
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$TARGET_NAME" || -z "$TARGET_EMAIL" ]]; then
  log_error "--name 与 --email 必填"
  usage >&2
  exit 2
fi
if [[ ! -d "$REPO_ROOT" ]]; then
  log_error "目录不存在: $REPO_ROOT"
  exit 2
fi
if ! command -v git-filter-repo >/dev/null 2>&1; then
  log_error "未找到 git-filter-repo，安装: pip install git-filter-repo"
  exit 2
fi

RUN_TS="$(date +%Y%m%d_%H%M%S)"
# 日志默认放临时目录：这个工具会在任意仓库里跑，不该往别人的工作树里写东西。
# 要留档就显式 --log-dir。
LOG_ROOT="${LOG_DIR_OVERRIDE:-${TMPDIR:-/tmp}/repo-fix-git-authors}"
LOG_DIR="$LOG_ROOT/$RUN_TS"
mkdir -p "$LOG_DIR"
SCRIPT_LOG="$LOG_DIR/script.log"
# 整脚本输出同时落盘，事后可核对；tee 在退出前等一拍，避免尾巴丢
exec > >(tee -a "$SCRIPT_LOG") 2>&1

confirm() {
  [[ "$AUTO_YES" == true ]] && return 0
  local answer
  read -r -p "[确认] $1 [y/N]: " answer
  [[ "${answer,,}" == y || "${answer,,}" == yes ]]
}

list_repos() {
  find "$REPO_ROOT" -maxdepth 8 -name .git 2>/dev/null |
    grep -v '/\.repo/' |
    grep -v '/\.worktrees/' |
    grep -v '/node_modules/' |
    sed 's|/\.git$||' |
    sort
}

# 返回 0 表示需要修复
needs_fix() {
  local repo="$1" emails p rest
  emails="$(git -C "$repo" log --format='%ae' --all 2>/dev/null | sort -u)"
  [[ -n "$emails" ]] || return 1 # 空仓库不用管
  for p in "${KEEP_PATTERNS[@]}"; do
    [[ -n "$p" ]] || continue
    emails="$(printf '%s\n' "$emails" | grep -v -F "$p" || true)"
  done
  rest="$(printf '%s\n' "$emails" | grep -v -F -x "$TARGET_EMAIL" | grep -v '^$' || true)"
  [[ -n "$rest" ]]
}

snapshot() {
  git -C "$1" log --format='%ad%x09%s' --date=short --all 2>/dev/null | sort
}

save_remotes() {
  git -C "$1" remote -v 2>/dev/null | awk '/\(fetch\)/{print $1, $2}' >"$2"
}

restore_remotes() {
  local repo="$1" file="$2" name url
  [[ -s "$file" ]] || return 0
  while read -r name url; do
    [[ -n "$name" && -n "$url" ]] || continue
    if git -C "$repo" remote get-url "$name" >/dev/null 2>&1; then
      git -C "$repo" remote set-url "$name" "$url"
    else
      git -C "$repo" remote add "$name" "$url"
    fi
  done <"$file"
}

rewrite() {
  local repo="$1" body
  body="keep = '''${KEEP_PATTERNS[*]}'''.split()
if not any(p.encode() in commit.author_email for p in keep):
    commit.author_name     = b'''${TARGET_NAME}'''
    commit.author_email    = b'''${TARGET_EMAIL}'''
    commit.committer_name  = b'''${TARGET_NAME}'''
    commit.committer_email = b'''${TARGET_EMAIL}'''"
  git -C "$repo" filter-repo --commit-callback "$body" --force
}

force_push() {
  local repo="$1" file="$2" name url ref branch pushed
  if [[ ! -s "$file" ]]; then
    log_warn "无 remote，跳过推送"
    return 0
  fi
  while read -r name url; do
    [[ -n "$name" && -n "$url" ]] || continue
    log_info "强推 → $name ($url)"
    pushed=0
    while read -r ref; do
      branch="${ref#refs/heads/}"
      git -C "$repo" push --force "$name" "$ref:refs/heads/$branch" || return 1
      pushed=$((pushed + 1))
    done < <(git -C "$repo" for-each-ref --format='%(refname)' refs/heads/)
    ((pushed > 0)) || log_warn "$name 下没有本地分支，跳过"
  done <"$file"
}

process_repo() {
  local repo="$1" name dir before after
  name="$(basename "$repo")"
  dir="$LOG_DIR/$name"
  mkdir -p "$dir"

  if ! needs_fix "$repo"; then
    log_info "[$name] author 已全部正确，跳过"
    return 0
  fi

  before="$(snapshot "$repo")"
  printf '%s\n' "$before" >"$dir/log_before.txt"
  save_remotes "$repo" "$dir/remotes.txt"
  log_warn "[$name] 存在非目标 author 的提交（共 $(printf '%s\n' "$before" | wc -l) 个）"

  if [[ "$DRY_RUN" == true ]]; then
    log_warn "[$name] DRY-RUN：不重写、不推送"
    return 0
  fi
  if ! confirm "重写 [$name] 的 author 历史？"; then
    log_info "[$name] 已取消"
    return 0
  fi

  if ! rewrite "$repo"; then
    log_error "[$name] filter-repo 失败"
    return 1
  fi
  restore_remotes "$repo" "$dir/remotes.txt"

  after="$(snapshot "$repo")"
  printf '%s\n' "$after" >"$dir/log_after.txt"
  if ! diff -q <(printf '%s\n' "$before") <(printf '%s\n' "$after") >/dev/null; then
    diff <(printf '%s\n' "$before") <(printf '%s\n' "$after") >"$dir/diff.txt" || true
    log_error "[$name] 重写后「日期+标题」变了，见 $dir/diff.txt"
    if ! confirm "对比异常，仍要强推 [$name]？"; then
      return 1
    fi
  fi

  if [[ "$DO_PUSH" == false ]]; then
    log_warn "[$name] --no-push：已重写未推送"
    return 0
  fi
  if ! confirm "强推 [$name] 到全部 remote？"; then
    log_info "[$name] 已取消推送"
    return 0
  fi
  if ! force_push "$repo" "$dir/remotes.txt"; then
    log_error "[$name] 推送失败"
    return 1
  fi
  log_success "[$name] 完成"
}

main() {
  log_section "repo-fix-git-authors"
  log_info "目标 author : $TARGET_NAME <$TARGET_EMAIL>"
  log_info "扫描目录   : $REPO_ROOT"
  log_info "DRY-RUN=$DRY_RUN  AUTO-YES=$AUTO_YES  PUSH=$DO_PUSH"
  log_info "日志       : $LOG_DIR"

  local repos=() ok=0 fail=0 r
  mapfile -t repos < <(list_repos)
  if ((${#repos[@]} == 0)); then
    log_error "在 $REPO_ROOT 下没找到 git 仓库"
    exit 1
  fi
  log_info "发现 ${#repos[@]} 个仓库"

  for r in "${repos[@]}"; do
    if process_repo "$r"; then
      ok=$((ok + 1))
    else
      fail=$((fail + 1))
    fi
  done

  log_section "汇总"
  log_info "总计 ${#repos[@]} / 成功 $ok / 失败 $fail"
  ((fail == 0))
}

main
