"""E-007 重试与指数退避：只重试可重试错误，退避序列翻倍，次数封顶。"""

import time


class TransientError(Exception):
    """环境临时问题：可重试。"""


class ValidationError(Exception):
    """输入问题：不重试，立即失败。"""


class FlakyClient:
    """前 fail_times 次调用抛 TransientError，之后成功。"""

    def __init__(self, fail_times):
        self.fail_times = fail_times
        self.calls = 0

    def fetch(self, _attempt):
        self.calls += 1
        if self.calls <= self.fail_times:
            raise TransientError("connect-refused")
        return "payload-7"


def bad_input(_attempt):
    raise ValidationError("age must be a positive integer")


def with_retry(op, retries, base_ms):
    delays = []
    for attempt in range(1, retries + 1):
        try:
            return op(attempt), delays
        except TransientError as err:
            if attempt == retries:
                raise
            delay_ms = base_ms * 2 ** (attempt - 1)
            delays.append(delay_ms)
            print(f"attempt {attempt} failed: TRANSIENT {err}")
            time.sleep(delay_ms / 1000)
    raise AssertionError("unreachable")


def main():
    result, delays = with_retry(FlakyClient(2).fetch, retries=3, base_ms=10)
    print(f"attempt 3 ok: got {result}")
    print(f"backoff: retries={len(delays)} delays={','.join(str(d) for d in delays)}ms")

    try:
        with_retry(bad_input, retries=3, base_ms=10)
    except ValidationError as err:
        print(f"no-retry: {type(err).__name__} rejected immediately ({err})")
    print("rule: retry only TRANSIENT errors, back off exponentially, cap the attempts")


if __name__ == "__main__":
    main()
