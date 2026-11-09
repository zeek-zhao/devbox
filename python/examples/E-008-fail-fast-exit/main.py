"""E-008 快速失败与退出码协议：错误类别映射到唯一退出码，不拖到深处才炸。"""

import sys

EXIT_OK = 0
EXIT_DATA = 1
EXIT_USAGE = 2


def usage_error(message):
    print(f"error: {message}", file=sys.stderr)
    raise SystemExit(EXIT_USAGE)


def data_error(message):
    print(f"error: {message}", file=sys.stderr)
    raise SystemExit(EXIT_DATA)


def validate_limit(raw):
    if not raw.isdigit():
        usage_error("--limit requires a positive integer")
    if int(raw) > 100:
        data_error(f"--limit {raw} exceeds maximum 100")
    return f"limit={int(raw)} accepted"


print(f"protocol: usage={EXIT_USAGE} data={EXIT_DATA} success={EXIT_OK}")


def probe(name, fn):
    try:
        fn()
    except SystemExit as err:
        print(f"{name} -> exit={err.code}")


probe("usage-error", lambda: validate_limit("abc"))
probe("data-error", lambda: validate_limit("200"))
print(f"success: {validate_limit('10')} -> exit={EXIT_OK}")
print("rule: fail at the boundary with a typed exit code, not deep inside")
