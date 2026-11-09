"""E-013 未捕获异常边界：线程异常经 excepthook 兜底记录一次，进程不静默。"""

import threading


def boom():
    raise ZeroDivisionError("division by zero")


caught = []


def hook(args):
    caught.append(f"uncaught: {args.exc_type.__name__}: {args.exc_value}")


def main():
    threading.excepthook = hook  # 兜底：任何线程漏掉的异常都在这里被记录一次
    worker = threading.Thread(target=boom, name="worker")
    worker.start()
    worker.join()
    print(caught[0])
    print("boundary: unexpected errors are logged once, process keeps running")


if __name__ == "__main__":
    main()
