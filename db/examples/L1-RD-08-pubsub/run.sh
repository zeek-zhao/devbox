#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../scripts/lib/common.sh"
cd "$HERE"

py_file <(cat <<'PY'
import redis

PREFIX = "l1-rd-08:"
r = redis.Redis(host="redis", port=6379, password="devbox", decode_responses=True)
for key in r.scan_iter(match=PREFIX + "*"):
    r.unlink(key)
channel = PREFIX + "news"
direct = r.pubsub()
pattern = r.pubsub()
direct.subscribe(channel)
pattern.psubscribe(PREFIX + "*")


def wait_for_subscription(pubsub, expected, field):
    for _ in range(10):
        message = pubsub.get_message(timeout=1)
        if message and message["type"] in ("subscribe", "psubscribe"):
            if message[field] == expected:
                return
    raise RuntimeError("subscription confirmation was not received")


wait_for_subscription(direct, channel, "channel")
wait_for_subscription(pattern, PREFIX + "*", "channel")
for value in ("one", "two"):
    r.publish(channel, value)
direct_messages = []
pattern_messages = []
for _ in range(10):
    if len(direct_messages) < 2:
        message = direct.get_message(timeout=1)
        if message and message["type"] == "message":
            direct_messages.append(message["data"])
    if len(pattern_messages) < 2:
        message = pattern.get_message(timeout=1)
        if message and message["type"] == "pmessage":
            pattern_messages.append(message["data"])
    if len(direct_messages) == 2 and len(pattern_messages) == 2:
        break
if direct_messages != ["one", "two"] or pattern_messages != ["one", "two"]:
    raise RuntimeError(f"unexpected pubsub messages: {direct_messages}, {pattern_messages}")
print(f"subscribe={','.join(direct_messages)}")
print(f"psubscribe={','.join(pattern_messages)}")
stream = PREFIX + "stream"
r.xadd(stream, {"payload": "durable"})
print(f"stream={r.xrange(stream)[0][1]['payload']}")
direct.close()
pattern.close()
r.close()
PY
)
