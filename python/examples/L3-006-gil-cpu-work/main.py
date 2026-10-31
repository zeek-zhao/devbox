from multiprocessing import Pool
from threading import Thread


def cpu_work(limit: int) -> tuple[int, int]:
    total = 0
    operations = 0
    for value in range(limit):
        total += value * value
        operations += 1
    return total, operations


def run_threads(work_items: list[int]) -> list[tuple[int, int]]:
    results: list[tuple[int, int] | None] = [None] * len(work_items)
    threads = [
        Thread(target=lambda index=index, limit=limit: results.__setitem__(index, cpu_work(limit)))
        for index, limit in enumerate(work_items)
    ]
    for thread in threads:
        thread.start()
    for thread in threads:
        thread.join()
    return [result for result in results if result is not None]


def main() -> None:
    work_items = [400, 600, 800]
    serial_results = [cpu_work(limit) for limit in work_items]
    thread_results = run_threads(work_items)
    with Pool(processes=2) as pool:
        process_results = pool.map(cpu_work, work_items)

    assert serial_results == thread_results == process_results
    expected_operations = sum(work_items)
    assert sum(count for _, count in serial_results) == expected_operations

    print("serial, thread, process results match: true")
    print(f"work items: {len(work_items)}")
    print(f"operations per strategy: {expected_operations}")
    print("standard CPython GIL: Python bytecode threads do not run in parallel")
    print("processes: independent interpreters")


if __name__ == "__main__":
    main()
