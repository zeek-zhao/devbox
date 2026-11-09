"""E-005 errno 映射：OSError 子类与 errno 值互为表里，类别决定处理动作。"""

import errno

ACTION = {
    "MISSING": "create-or-skip",
    "DENIED": "stop-and-report",
    "TRANSIENT": "retry",
    "UNKNOWN": "fail-fast",
}


def classify(err):
    """OSError 子类是解释器内置的 errno 映射；映射不出来的按 UNKNOWN 保守处理。"""
    if isinstance(err, FileNotFoundError):
        return "MISSING"
    if isinstance(err, PermissionError):
        return "DENIED"
    if err.errno in (errno.EAGAIN, errno.EWOULDBLOCK):
        return "TRANSIENT"
    return "UNKNOWN"


def report(label, err):
    category = classify(err)
    print(
        f"{label}: errno={err.errno} type={type(err).__name__} "
        f"category={category} action={ACTION[category]}"
    )


def main():
    # 真实触发：路径不存在时解释器已把 errno 映射成 FileNotFoundError。
    try:
        open("/nonexistent/devbox-e005/missing.txt")
    except OSError as err:
        report("real-missing", err)

    # 合成构造：OSError(errno, msg) 会按 errno 自动选好子类。
    report("denied", OSError(errno.EACCES, "Permission denied"))
    report("transient", OSError(errno.EAGAIN, "Resource temporarily unavailable"))
    report("io", OSError(errno.EIO, "Input/output error"))
    print("mapping: errno values are the stable interface; subclasses are the built-in mapping")


if __name__ == "__main__":
    main()
