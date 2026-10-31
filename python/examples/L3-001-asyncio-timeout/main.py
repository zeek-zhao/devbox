import asyncio


async def fetch(label: str) -> str:
    await asyncio.sleep(0)
    return label


async def wait_for_release(started: asyncio.Event, cleanup: list[str]) -> None:
    started.set()
    try:
        await asyncio.Event().wait()
    finally:
        cleanup.append("released")


async def main() -> None:
    results = await asyncio.gather(fetch("beta"), fetch("alpha"))
    print(f"gathered: {','.join(sorted(results))}")

    started = asyncio.Event()
    cleanup: list[str] = []
    task = asyncio.create_task(wait_for_release(started, cleanup))
    await started.wait()
    try:
        await asyncio.wait_for(task, timeout=0.01)
    except TimeoutError:
        print("timeout caught: true")

    print(f"child cancelled: {task.cancelled()}")
    print(f"cleanup completed: {cleanup == ['released']}")


if __name__ == "__main__":
    asyncio.run(main())
