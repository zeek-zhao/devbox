#!/usr/bin/env bash
set -euo pipefail

cat >"$WORK/response.json" <<'JSON'
{
  "service": {
    "name": "api",
    "status": "ready",
    "message": "queue \"green\""
  },
  "checks": [
    {"name": "db", "ok": true},
    {"name": "cache", "ok": false}
  ]
}
JSON

jq -r '"service: \(.service.name) \(.service.status)",
  "message: \(.service.message)",
  (.checks[] | select(.ok) | "healthy: \(.name)")' "$WORK/response.json"
