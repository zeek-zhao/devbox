#!/usr/bin/env bash
# T-001-external-dependency 演练入口：健康对照 → 取证链三步（jobs → 302 → blob）
# → 401 坑判读 → 去凭证修复 → grep 真因 → 503 对照归因，七步串完整流程。
#
# 工具：bash + curl + python3。本 lab 不依赖任何容器镜像，也不访问真实网络：
# 全部 HTTP 交互只发生在 127.0.0.1 上的受控模拟服务（repro.sh 起）。
# GitHub 托管 ubuntu runner 与 devbox 各语言镜像均预装这三样。
#
# 用法：bash run.sh   （退出 0 = 演练流程与断言全部符合预期；非零 = 红，不许吞）
set -uo pipefail
cd "$(dirname "$0")" || exit

REPRO="$(pwd)/repro.sh"
BUILD="${TMPDIR:-/tmp}/devbox-shared-T-001-external-dependency"
TOKEN="Bearer SIMULATED-LOCAL-ONLY-TOKEN"  # 假令牌，只被本地模拟服务识别

pass=0
step() {
  echo
  echo "=== [step $1] $2 ==="
}
ok() {
  echo "  -> 符合预期"
  pass=$((pass + 1))
}
bad() { echo "  -> 不符合预期：$1" >&2; }

cleanup() { bash "$REPRO" stop >/dev/null 2>&1 || true; }
trap cleanup EXIT

step 1 "受控模拟服务就绪：/health 健康对照（前 60 秒只读检查①）"
out="$(bash "$REPRO" start)"
if [ $? -ne 0 ]; then
  echo "$out" >&2
  echo "RUN-FAIL：模拟服务起不来（python3 / curl 缺失或端口被占）" >&2
  exit 1
fi
echo "  | $out"
port="$(sed -E 's/^MOCK-READY port=//' <<<"$out")"
root="http://127.0.0.1:$port"
if [ "$(curl -s -o /dev/null -w '%{http_code}' "$root/health")" = "200" ]; then
  ok
else
  bad "/health 应答 200，服务未真正就绪"
fi

step 2 "取证链①：GET /actions/runs/<run_id>/jobs 找失败 job（带令牌 → 200）"
jobs_body="$BUILD/jobs.json"
code="$(curl -s -o "$jobs_body" -w '%{http_code}' -H "Authorization: $TOKEN" "$root/actions/runs/421000000/jobs")"
job_id="$(grep -oE '"id": ?[0-9]+' "$jobs_body" | head -1 | grep -oE '[0-9]+')"
echo "  | chain①: GET /actions/runs/<id>/jobs → HTTP $code, job id=$job_id"
if [ "$code" = "200" ] && [ -n "$job_id" ]; then
  ok
else
  bad "应 200 且解析出 job id（API 层鉴权失败？先查这里，别跳到下游）"
fi

step 3 "取证链②：GET /actions/jobs/<job_id>/logs → 302，Location 指向 blob"
hdr="$BUILD/logs-api-headers.txt"
code="$(curl -s -D "$hdr" -o /dev/null -w '%{http_code}' -H "Authorization: $TOKEN" "$root/actions/jobs/$job_id/logs")"
loc="$(grep -i '^Location:' "$hdr" | tr -d '\r' | awk '{print $2}')"
echo "  | chain②: GET /actions/jobs/<id>/logs → HTTP $code"
echo "  | chain②: Location=$loc"
if [ "$code" = "302" ] && [ -n "$loc" ]; then
  ok
  echo "  (日志正文不在 API 域名下：jobs logs 接口只回 302，真正的日志在 blob 上)"
else
  bad "应 302 且带 Location 头，实际 code=$code loc=${loc:-空}"
fi

step 4 "取证链③（真实踩过的坑）：第二次请求把 Authorization 也带上 → 401"
body="$BUILD/blob-401.txt"
code="$(curl -s -o "$body" -w '%{http_code}' -H "Authorization: $TOKEN" "$loc")"
echo "  | chain③(坑): 带 Authorization → HTTP $code"
grep -o '<Code>AuthenticationFailed</Code>' "$body" | sed 's/^/  | blob: /'
if [ "$code" = "401" ] && grep -q 'AuthenticationFailed' "$body"; then
  ok
  echo "  (本仓库真实踩过的坑，写成判读：同一个令牌在 chain① 是 200，到这里变 401——"
  echo "   变的不是凭证，是收件方。Azure blob 不认 GitHub 的 API 令牌，带了反而 401)"
else
  bad "应 401 且命中 AuthenticationFailed，实际 code=$code"
fi

step 5 "取证链③修复：第二次请求不带 Authorization → 200 拿到日志"
logf="$BUILD/job.log"
code="$(curl -s -o "$logf" -w '%{http_code}' "$loc")"
echo "  | chain③(修): 不带 Authorization → HTTP $code"
if [ "$code" = "200" ] && grep -q 'TLS handshake timeout' "$logf"; then
  ok
else
  bad "应 200 且日志可读，实际 code=$code"
fi

step 6 "grep 取证：从日志里捞真因（外部镜像源抖动伪装成整轨用例全挂）"
grep -nE 'error|timeout|service .* is not running' "$logf" | sed 's/^/  | /'
n="$(grep -cE 'error|timeout|service .* is not running' "$logf")"
if [ "$n" -ge 3 ]; then
  ok
  echo "  (TLS handshake timeout 是因，service not running / 用例全红是果——"
  echo "   根因在依赖侧，不在用例代码；按环境故障取证，不动用例)"
else
  bad "日志诊断行应命中 >=3，实际 $n"
fi

step 7 "归因对照：把依赖打挂（mode=down）→ 同样请求变 503，两种故障分得开"
curl -s "$root/__control?mode=down" >/dev/null
code_down="$(curl -s -o /dev/null -w '%{http_code}' "$loc")"
curl -s "$root/__control?mode=up" >/dev/null
code_back="$(curl -s -o /dev/null -w '%{http_code}' "$loc")"
echo "  | down: 同样不带 Authorization → HTTP $code_down（503 = 依赖本体不可用）"
echo "  | 恢复: mode=up 后 → HTTP $code_back（200 = 是否带凭证与可用性互不相干）"
if [ "$code_down" = "503" ] && [ "$code_back" = "200" ]; then
  ok
else
  bad "应得 down=503 / 恢复=200，实际 $code_down / $code_back"
fi

echo
if [ "$pass" -eq 7 ]; then
  echo "RUN-PASS：7/7 判定符合预期"
  exit 0
fi
echo "RUN-FAIL：$pass/7 判定符合预期" >&2
exit 1
