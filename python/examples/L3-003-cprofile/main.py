import cProfile
import pstats


def convert(value: int) -> int:
    return value * 2


def main() -> None:
    profiler = cProfile.Profile()
    for value in (3, 5, 8):
        profiler.runcall(convert, value)

    stats = pstats.Stats(profiler)
    calls = sorted(
        (function, values[1])
        for (_, _, function), values in stats.stats.items()
        if function == "convert"
    )
    for function, count in calls:
        print(f"{function}: {count}")


if __name__ == "__main__":
    main()
