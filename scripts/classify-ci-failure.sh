#!/usr/bin/env bash
# CI 失败三分类 + JSON trace（M12-CI-02，issue #338；非门禁脚本）
#
# 把一次 CI 失败按 docs/78-CI失败分类规范.md §2 的三分类枚举判定：
#   infra_transient / real_regression / flaky_test；证据不足写 UNVERIFIED（§4：不许猜）。
# 输出结构化 JSON trace，字段与 docs/80-M12度量规范.md §2 的 m12-traces schema 同构可消费
# （spec_version / rubric_version / run_id / head_sha / commands / assertions /
#   classification / unverified / owner / reviewed_at），
# 并补 docs/78 §4 的首次失败留痕块（首次结论 / 分类 / 重试结论 / 移除条件 / 取证）。
#
# 纪律（docs/78）：
#   - 分类只认首次结论；重试通过 ≠ flaky 也 ≠ 稳定，重试结果单独上报，不折叠成干净绿；
#   - flaky_test 需要「同一 head_sha 多次运行结论不一致」的完整序列作证据，
#     单次 fail→pass 重跑不足以判 flaky（§3），只登记不翻类；
#   - --force <class> 是人工判定通道（docs/78 §2 需人工判定时），必须在卡内留痕说明依据。
#
# 零依赖：bash + coreutils（grep/sed/sort）；python3 仅在 --pretty 时用于缩进。
# 退出码：0 = 分类成功（含 UNVERIFIED）；1 = 输入错误（日志文件不存在等）；2 = 用法错误。
#
# 用法：
#   bash scripts/classify-ci-failure.sh --log <logfile|-> [选项]
# 选项：
#   --run-id <id>          CI run id（缺省 UNVERIFIED）
#   --head-sha <sha>       提交 sha（缺省 UNVERIFIED）
#   --job <name>           失败 job 名（缺省 UNVERIFIED）
#   --step <name>          失败 step 名（缺省 UNVERIFIED）
#   --exit-code <n>        退出码（缺省 UNVERIFIED）
#   --retry-results <list> 同一 head_sha 各次 run 的结论序列（逗号分隔，含首次，
#                          按时间序，如 "fail,pass" 或 "fail,pass,fail"）
#   --archive-path <path>  首次失败日志留档路径（缺省 UNVERIFIED）
#   --removal-condition <s> 移除条件（docs/78 §4 必填字段；缺省 UNVERIFIED）
#   --force <class>        人工判定覆盖（三分类之一；须另附依据，见脚本头注释）
#   --pretty               JSON 缩进输出（需 python3）
set -u

PROG="$(basename "$0")"
usage() { sed -n '2,40p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }

log_file="" run_id="" head_sha="" job="" step="" exit_code=""
retry_results="" archive_path="" removal="" force="" pretty=""

while [ $# -gt 0 ]; do
  case "$1" in
    --log) [ $# -ge 2 ] || usage; log_file="$2"; shift 2 ;;
    --run-id) [ $# -ge 2 ] || usage; run_id="$2"; shift 2 ;;
    --head-sha) [ $# -ge 2 ] || usage; head_sha="$2"; shift 2 ;;
    --job) [ $# -ge 2 ] || usage; job="$2"; shift 2 ;;
    --step) [ $# -ge 2 ] || usage; step="$2"; shift 2 ;;
    --exit-code) [ $# -ge 2 ] || usage; exit_code="$2"; shift 2 ;;
    --retry-results) [ $# -ge 2 ] || usage; retry_results="$2"; shift 2 ;;
    --archive-path) [ $# -ge 2 ] || usage; archive_path="$2"; shift 2 ;;
    --removal-condition) [ $# -ge 2 ] || usage; removal="$2"; shift 2 ;;
    --force) [ $# -ge 2 ] || usage; force="$2"; shift 2 ;;
    --pretty) pretty=1; shift ;;
    *) usage ;;
  esac
done

[ -n "$log_file" ] || usage
if [ "$log_file" != "-" ] && [ ! -f "$log_file" ]; then
  echo "ERROR: 日志文件不存在: $log_file" >&2
  exit 1
fi

for v in "$force"; do
  case "$v" in
    ""|infra_transient|real_regression|flaky_test) ;;
    *) echo "ERROR: --force 只接受三分类枚举值" >&2; exit 2 ;;
  esac
done

U="UNVERIFIED"
[ -n "$run_id" ] || run_id="$U"
[ -n "$head_sha" ] || head_sha="$U"
[ -n "$job" ] || job="$U"
[ -n "$step" ] || step="$U"
[ -n "$exit_code" ] || exit_code="$U"
[ -n "$archive_path" ] || archive_path="$U"
[ -n "$removal" ] || removal="$U"

# ---------- 信号匹配（docs/78 §2.1 / §2.2 / §2.3） ----------
log_data="/dev/stdin"
[ "$log_file" = "-" ] || log_data="$log_file"

infra_kw_regex='TLS handshake timeout|Could not resolve|service "[^"]+" is not running|等待超时|Error response from daemon|failed to solve|No space left on device|Could not find a version that satisfies the requirement|toomanyrequests|i/o timeout'
code_kw_regex='AssertionError|assert .* failed|FAILED \(failures|panic:|Segmentation fault|E  *assert'

matched_infra="$(grep -Ein "$infra_kw_regex" "$log_data" 2>/dev/null | head -10 || true)"
if [ "$log_file" != "-" ]; then
  matched_code="$(grep -Ein "$code_kw_regex" "$log_file" 2>/dev/null | head -10 || true)"
else
  # stdin 已被上一条 grep 消费，代码信号对 stdin 输入跳过（记录 UNVERIFIED）
  matched_code=""
fi

classification=""
keywords="[]"
evidence=""

json_escape() {
  # 单行 JSON 字符串转义：反斜杠、双引号、控制字符
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | tr -d '\000-\010\013\014\016-\037' | sed ':a;N;$!ba;s/\n/\\n/g'
}

kw_to_json() {
  # 把 grep 命中行转成 JSON 字符串数组（每行一个元素）
  if [ -z "$1" ]; then
    echo "[]"
    return
  fi
  local first=1 out="[" line esc
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    esc="$(json_escape "$line")"
    if [ $first -eq 1 ]; then first=0; out="$out\"$esc\""; else out="$out,\"$esc\""; fi
  done <<< "$1"
  echo "$out]"
}

if [ -n "$force" ]; then
  classification="$force"
  evidence="人工判定通道（--force）；依据须在对应卡内评论留痕（docs/78 §2）"
elif [ -n "$matched_infra" ]; then
  classification="infra_transient"
  keywords="$(kw_to_json "$matched_infra")"
elif [ -n "$matched_code" ]; then
  classification="real_regression"
  keywords="$(kw_to_json "$matched_code")"
else
  classification="UNVERIFIED"
fi

# flaky 判定：同一 head_sha 多次 run 结论不一致（同时含 pass 与 fail/cancel）
flaky_note=""
if [ -n "$retry_results" ]; then
  has_pass="$(printf '%s' "$retry_results" | tr ',' '\n' | grep -cx pass || true)"
  has_bad="$(printf '%s' "$retry_results" | tr ',' '\n' | grep -cE '^(fail|failure|cancelled)$' || true)"
  if [ "$has_pass" -gt 0 ] && [ "$has_bad" -gt 0 ]; then
    if [ -z "$force" ] && [ "$classification" != "infra_transient" ]; then
      # 完整不一致序列成立才判 flaky（docs/78 §2.3）；infra 信号优先（§2.1 环境抖动可解释翻转）
      classification="flaky_test"
      flaky_note="同一 head_sha 结论序列: $retry_results"
    else
      flaky_note="结论序列 $retry_results 存在翻转，但分类以首次结论证据为准（docs/78 §3：重试不翻类）"
    fi
  else
    flaky_note="重试序列 $retry_results 无翻转；rerun 通过 ≠ flaky 也 ≠ 稳定（docs/78 §3）"
  fi
fi

# ---------- 组装 JSON（docs/80 §2 字段 + docs/78 §4 留痕块） ----------
unverified_items=""
add_unverified() {
  local item="$1"
  if [ -z "$unverified_items" ]; then
    unverified_items="\"$item\""
  else
    unverified_items="$unverified_items,\"$item\""
  fi
}
[ "$run_id" = "$U" ] && add_unverified "run_id: 未提供 --run-id"
[ "$head_sha" = "$U" ] && add_unverified "head_sha: 未提供 --head-sha"
[ "$job" = "$U" ] && add_unverified "job: 未提供 --job"
[ "$step" = "$U" ] && add_unverified "step: 未提供 --step"
[ "$exit_code" = "$U" ] && add_unverified "exit_code: 未提供 --exit-code"
[ "$archive_path" = "$U" ] && add_unverified "archive_path: 未提供 --archive-path"
[ "$removal" = "$U" ] && add_unverified "removal_condition: 未提供 --removal-condition"
[ "$classification" = "UNVERIFIED" ] && add_unverified "classification: 证据不足，docs/78 §4 禁止猜测"
[ -z "$retry_results" ] && add_unverified "retry: 未提供 --retry-results"
[ "$log_file" = "-" ] && add_unverified "code_signals: stdin 输入只扫描一遍，代码信号未检"

retry_json="null"
if [ -n "$retry_results" ]; then
  retry_json="{\"same_head_sha_sequence\": \"$(json_escape "$retry_results")\", \"note\": \"$(json_escape "${flaky_note:-}")\"}"
fi

json="$(cat <<EOF
{
  "spec_version": "v2",
  "rubric_version": "m12-rubric-1",
  "model": "UNVERIFIED",
  "session_id": "UNVERIFIED",
  "run_id": "$(json_escape "$run_id")",
  "head_sha": "$(json_escape "$head_sha")",
  "commands": [],
  "assertions": ["分类判定依据 docs/78-CI失败分类规范.md §2；JSON 结构对齐 docs/80-M12度量规范.md §2；顶层 classification 为 verifier 级结论（pass/fail/revise/escalate），不在本脚本判定范围，恒写 UNVERIFIED，三分类见 ci_failure.classification"],
  "classification": "UNVERIFIED",
  "unverified": [${unverified_items}],
  "owner": "zeek.zhao <zeek.zhao@foxmail.com>",
  "reviewed_at": "UNVERIFIED",
  "ci_failure": {
    "job": "$(json_escape "$job")",
    "step": "$(json_escape "$step")",
    "exit_code": "$(json_escape "$exit_code")",
    "classification": "$(json_escape "$classification")",
    "first_conclusion": "failure",
    "retry": ${retry_json},
    "first_failure_archive": "$(json_escape "$archive_path")",
    "removal_condition": "$(json_escape "$removal")",
    "signals": {
      "infra": ${keywords:-[]},
      "note": "$(json_escape "${evidence:-}")"
    }
  }
}
EOF
)"

# ---------- 输出：人读摘要到 stderr，JSON 到 stdout（可直接重定向进 CI summary/artifact） ----------
echo "[classify] 首次结论: failure（以首次为准，重试不折叠成干净绿）" >&2
echo "[classify] 分类: $classification" >&2
if [ -n "$flaky_note" ]; then
  echo "[classify] 重试: $flaky_note" >&2
fi
infra_n=0
code_n=0
[ -n "$matched_infra" ] && infra_n="$(printf '%s' "$matched_infra" | grep -c . )"
[ -n "$matched_code" ] && code_n="$(printf '%s' "$matched_code" | grep -c . )"
echo "[classify] 证据: 命中 infra ${infra_n} 行, code ${code_n} 行" >&2
echo "[classify] 留档: $archive_path；移除条件: $removal" >&2

if [ -n "$pretty" ] && command -v python3 >/dev/null 2>&1; then
  printf '%s' "$json" | python3 -m json.tool
else
  printf '%s\n' "$json"
fi
exit 0
