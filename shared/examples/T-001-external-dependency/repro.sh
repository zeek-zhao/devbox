#!/usr/bin/env bash
# T-001-external-dependency 受控模拟：本地回环起一个 HTTP 服务，模拟
# 「GitHub API 拉日志 → 302 跳 Azure blob → 下载日志」的真实取证链路。
# 不真断网、不访问任何真实网络（docs/72 §3 类型②实验；坑本体登记于 docs/73 §9）。
#
# 模拟规则（与真实踩坑一一对应）：
#   GET /health                  → 200 ok（健康对照）
#   GET /actions/runs/<id>/jobs  带 Authorization → 200 JSON（job 清单）；不带 → 401
#   GET /actions/jobs/<id>/logs  → 302 + Location: /blob/logs?sig=SIMULATED&...
#   GET /blob/...                不带 Authorization → 200 日志正文（健康）
#                                带 Authorization → 401 AuthenticationFailed
#                                （真实踩过的坑：把 API 令牌带到 Azure blob 会被拒，
#                                  docs/73 §9「第二次请求不要带 Authorization 头」）
#   GET|POST /__control?mode=down → blob 端改返 503（模拟外部依赖本体不可用）
#   GET|POST /__control?mode=up   → 恢复 200
#
# 用法：
#   bash repro.sh start   # 起模拟服务，输出 MOCK-READY port=<N>（run.sh 各步复用）
#   bash repro.sh stop    # 停服务
#   bash repro.sh         # 最小复现：健康对照 → 带 Authorization 401（故障）→ 退出非零
set -uo pipefail
cd "$(dirname "$0")" || exit 1

BUILD="${TMPDIR:-/tmp}/devbox-shared-T-001-external-dependency"
mkdir -p "$BUILD"
PORT_FILE="$BUILD/port"
PID_FILE="$BUILD/pid"
BASE="http://127.0.0.1"                    # 只绑回环，不出网
TOKEN="Bearer SIMULATED-LOCAL-ONLY-TOKEN"  # 假令牌：只被本地模拟服务识别，无任何真实凭证

write_server() {
  cat > "$BUILD/server.py" <<'PY'
import json
import os
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

build = sys.argv[1]
state = {"mode": os.environ.get("LAB_SIM", "up")}
JOB_ID = 730000000
LOG_BODY = (
    "2026-11-06T09:00:01.0000000Z [INFO] job=用例-db (mongo mysql postgres) start\n"
    "2026-11-06T09:00:04.0000000Z ##[error] Timeout: TLS handshake timeout (registry mirror)\n"
    '2026-11-06T09:00:05.0000000Z ##[error] service "toolbox" is not running\n'
    "2026-11-06T09:00:06.0000000Z ##[error] 77 个用例 76 个失败\n"
)


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):  # 静默访问日志，输出留给演练脚本
        pass

    def _send(self, code, body=b"", content_type="text/plain; charset=utf-8", headers=()):
        self.send_response(code)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        for k, v in headers:
            self.send_header(k, v)
        self.end_headers()
        if body:
            self.wfile.write(body)

    def do_GET(self):
        path, _, query = self.path.partition("?")
        if path == "/health":
            self._send(200, b"ok")
        elif path == "/__control":
            q = dict(p.split("=", 1) for p in query.split("&") if "=" in p)
            if q.get("mode") in ("up", "down"):
                state["mode"] = q["mode"]
                self._send(200, ("mode=" + q["mode"]).encode())
            else:
                self._send(400, b"bad mode")
        elif path.startswith("/actions/runs/") and path.endswith("/jobs"):
            if self.headers.get("Authorization", "").startswith("Bearer "):
                jobs = {
                    "total_count": 1,
                    "jobs": [
                        {
                            "id": JOB_ID,
                            "name": "用例-db (mongo mysql postgres)",
                            "conclusion": "failure",
                        }
                    ],
                }
                self._send(200, json.dumps(jobs).encode(), "application/json")
            else:
                self._send(401, b'{"message":"Requires authentication"}')
        elif path.startswith("/actions/jobs/") and path.endswith("/logs"):
            host = self.headers.get("Host", "127.0.0.1")
            loc = "http://%s/blob/logs?sig=SIMULATED&se=2026-11-06T10%%3A00%%3A00Z" % host
            self._send(302, b"", headers=[("Location", loc)])
        elif path.startswith("/blob/"):
            if state["mode"] == "down":
                self._send(503, "Service Unavailable (simulated: 外部依赖本体不可用)".encode("utf-8"))
            elif self.headers.get("Authorization"):
                body = (
                    '<?xml version="1.0" encoding="utf-8"?>\n'
                    "<Error><Code>AuthenticationFailed</Code>"
                    "<Message>Server failed to authenticate the request.</Message></Error>\n"
                )
                self._send(401, body.encode(), "application/xml")
            else:
                self._send(200, LOG_BODY.encode())
        else:
            self._send(404, b"not found")

    do_POST = do_GET


srv = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
with open(os.path.join(build, "port"), "w") as f:
    f.write(str(srv.server_address[1]))
srv.serve_forever()
PY
}

stop_server() {
  if [ -f "$PID_FILE" ]; then
    local pid
    pid="$(cat "$PID_FILE")"
    kill "$pid" >/dev/null 2>&1 || true
    rm -f "$PID_FILE" "$PORT_FILE"
  fi
}

start_server() {
  stop_server
  write_server
  LAB_SIM="${LAB_SIM:-up}" python3 "$BUILD/server.py" "$BUILD" >"$BUILD/server.log" 2>&1 &
  echo $! >"$PID_FILE"
  local _ port=""
  for _ in $(seq 1 50); do
    if [ -f "$PORT_FILE" ]; then port="$(cat "$PORT_FILE")"; break; fi
    sleep 0.1
  done
  if [ -z "$port" ]; then
    echo "repro: 模拟服务未就绪（见 $BUILD/server.log）" >&2
    stop_server
    return 1
  fi
  for _ in $(seq 1 50); do
    if curl -fsS "$BASE:$port/health" >/dev/null 2>&1; then
      echo "MOCK-READY port=$port"
      return 0
    fi
    sleep 0.1
  done
  echo "repro: /health 探测失败（见 $BUILD/server.log）" >&2
  stop_server
  return 1
}

case "${1:-repro}" in
  start) start_server ;;
  stop) stop_server ;;
  repro)
    out="$(start_server)" || { echo "$out" >&2; exit 2; }
    port="$(sed -E 's/^MOCK-READY port=//' <<<"$out")"
    blob="$BASE:$port/blob/logs?sig=SIMULATED"
    # 健康对照：第二次请求不带 Authorization（跟随 302 到 blob）
    code_up="$(curl -s -o /dev/null -w '%{http_code}' -L "$blob")"
    echo "repro: 对照（不带 Authorization）→ HTTP $code_up（健康时 200）"
    # 故障复现：把 API 请求的 Authorization 头原样带到 blob（真实踩坑写法）
    body="$BUILD/repro-blob-body.txt"
    code_bad="$(curl -s -o "$body" -w '%{http_code}' -L -H "Authorization: $TOKEN" "$blob")"
    echo "repro: 故障（带 Authorization）→ HTTP $code_bad（Azure blob 拒收凭证）"
    grep -o '<Code>AuthenticationFailed</Code>' "$body" | sed 's/^/repro:   /'
    stop_server
    if [ "$code_bad" = "401" ]; then
      echo "repro: 故障已复现（外部依赖拒收凭证 → 401），按 docs/72 §2 以非零退出码表示"
      exit 1
    fi
    echo "repro: 故障未复现（期望 401，实际 $code_bad）" >&2
    exit 0
    ;;
  *)
    echo "用法: bash repro.sh [start|stop]" >&2
    exit 2
    ;;
esac
