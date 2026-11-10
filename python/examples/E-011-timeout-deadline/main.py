"""E-011 超时与截止：等待要有上限，超时是独立的错误类别，命中后要善后。"""

import time
from concurrent.futures import ThreadPoolExecutor
from concurrent.futures import TimeoutError as FutureTimeout


def slow(seconds):
    time.sleep(seconds)
    return "done"


def main():
    with ThreadPoolExecutor(max_workers=1) as pool:
        future = pool.submit(slow, 0.2)
        try:
            result = future.result(timeout=0.05)
        except FutureTimeout:
            print("deadline-hit: TimeoutError after 0.05s")
            print("deadline-class: TIMEOUT -> action=cancel-and-report")
            future.cancel()  # 善后：尝试取消任务，防止占用线程池
        else:
            print(f"deadline-hit: got {result}")
        print(f"fast-path: got {pool.submit(slow, 0.05).result()}")
    print("rule: every wait has a deadline; timeouts are classified, never ignored")


if __name__ == "__main__":
    main()
