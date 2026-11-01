#!/usr/bin/env bash
# ==================================================================
# check-authors.sh —— 提交身份门禁
# ------------------------------------------------------------------
# 校验三件事：
#   1) author 邮箱在白名单里
#   2) committer 邮箱在白名单里
#   3) 提交信息里没有 AI 署名尾巴（Co-authored-by: Copilot/Claude/GPT…）
#
# 用法：
#   check-authors.sh                      # 校验 HEAD 的完整历史
#   check-authors.sh --all                # 同上（显式写法）
#   check-authors.sh <range>              # 校验 git rev-list <range>，如 main..HEAD
#   check-authors.sh <range> --warn-only  # 只告警，不判失败（外部 PR 用）
#
# 为什么分两档：
#   main 的历史要求身份唯一，这是硬约束；
#   但外部贡献者保留自己的署名是开源惯例，强行改成维护者邮箱等于伪造。
#   所以 pull_request 上只检查「有没有 AI 署名尾巴」，身份只告警。
#
# 白名单：.github/authors-allowlist.txt
# 对应 CI job：ci.yml 的 authors
# ==================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

ALLOWLIST="${AUTHORS_ALLOWLIST:-.github/authors-allowlist.txt}"
WARN_ONLY=0
RANGE=""

for arg in "$@"; do
  case "$arg" in
    --all)       RANGE="--all" ;;
    --warn-only) WARN_ONLY=1 ;;
    -h|--help)   sed -n '2,28p' "$0"; exit 0 ;;
    -*)          echo "未知选项：$arg" >&2; exit 2 ;;
    *)           RANGE="$arg" ;;
  esac
done

if [ ! -f "$ALLOWLIST" ]; then
  echo "[authors] 找不到白名单：$ALLOWLIST" >&2
  exit 2
fi

# 读白名单：去掉注释与空白行，只留邮箱
allowed="$(grep -vE '^[[:space:]]*(#|$)' "$ALLOWLIST" | tr -d '[:space:]')"
if [ -z "$allowed" ]; then
  echo "[authors] 白名单为空，拒绝通过" >&2
  exit 2
fi

# 取提交范围
if [ -z "$RANGE" ] || [ "$RANGE" = "--all" ]; then
  revs="$(git rev-list --all)"
  scope="全部历史"
else
  revs="$(git rev-list "$RANGE" 2>/dev/null || true)"
  if [ -z "$revs" ]; then
    # 空范围是合法情况（例如只有 merge 提交），不是错误
    echo "[authors] 范围 $RANGE 内没有提交，跳过"
    exit 0
  fi
  scope="范围 $RANGE"
fi

total=0
bad_author=0
bad_committer=0
bad_trailer=0
report=""

while IFS= read -r sha; do
  [ -n "$sha" ] || continue
  total=$((total + 1))

  # %ae = author email, %ce = committer email, %B = 原始正文
  meta="$(git log -1 --format='%ae%n%ce%n%B' "$sha")"
  a_email="$(printf '%s\n' "$meta" | sed -n '1p')"
  c_email="$(printf '%s\n' "$meta" | sed -n '2p')"
  body="$(printf '%s\n' "$meta" | sed -n '3,$p')"
  short="$(git log -1 --format='%h %s' "$sha")"

  if ! grep -qxF -- "$a_email" <<<"$allowed"; then
    bad_author=$((bad_author + 1))
    report="${report}  [author]    ${short}  <- ${a_email}"$'\n'
  fi

  if ! grep -qxF -- "$c_email" <<<"$allowed"; then
    bad_committer=$((bad_committer + 1))
    report="${report}  [committer] ${short}  <- ${c_email}"$'\n'
  fi

  if printf '%s' "$body" | grep -qiE 'co-authored-by:.*(copilot|claude|anthropic|openai|gpt|codex|cursor|gemini|devin|aider)|^generated (with|by) \[?(copilot|claude|chatgpt)'; then
    bad_trailer=$((bad_trailer + 1))
    report="${report}  [ai-trailer] ${short}"$'\n'
  fi
done <<<"$revs"

echo "==> 提交身份校验（${scope}，共 ${total} 个提交）"
echo "    白名单：$(echo "$allowed" | tr '\n' ' ')"

bad=$((bad_author + bad_committer + bad_trailer))
if [ "$bad" -eq 0 ]; then
  echo "    全部合规"
  exit 0
fi

printf '%s' "$report"

if [ "$WARN_ONLY" -eq 1 ]; then
  echo "::warning::发现 ${bad} 处身份异常（warn-only，不判失败）"
  exit 0
fi

echo "" >&2
echo "发现 ${bad} 处身份异常：" >&2
echo "  author 不在白名单：${bad_author}" >&2
echo "  committer 不在白名单：${bad_committer}" >&2
echo "  AI 署名尾巴：${bad_trailer}" >&2
echo "" >&2
echo "修法：" >&2
echo "  - 新提交：git config user.name/user.email 设成白名单里的身份" >&2
echo "  - 已有提交：git rebase --exec 'git commit --amend --no-edit --reset-author' <base>" >&2
echo "  - 外部贡献者：评审后把其邮箱加进 $ALLOWLIST" >&2
exit 1
