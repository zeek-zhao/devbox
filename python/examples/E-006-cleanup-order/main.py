"""E-006 错误路径清理顺序：ExitStack 逆序回滚，suppress 只吞清理类异常。"""

import contextlib


class Resource:
    def __init__(self, name, log):
        self.name = name
        self.log = log

    def close(self):
        self.log.append(f"close: {self.name}")


def acquire_all(log):
    with contextlib.ExitStack() as stack:
        log.append("open: a")
        stack.callback(Resource("a", log).close)
        log.append("open: b")
        stack.callback(Resource("b", log).close)
        log.append("fail: boom")
        raise RuntimeError("boom")


log = []
try:
    acquire_all(log)
except RuntimeError as err:
    log.append(f"caught: {err}")

with contextlib.suppress(ValueError):
    raise ValueError("flaky-optional-cleanup")  # 可选清理失败：吞掉并继续
log.append("suppress: continued after optional cleanup failure")

print("\n".join(log))
