from multiprocessing import Pool


def normalize(value: str) -> str:
    return value.strip().lower()


def main() -> None:
    with Pool(processes=2) as pool:
        results = pool.map(normalize, [" Ada ", "GRACE", " Linus "])
    print(f"normalized: {','.join(results)}")
    print(f"items: {len(results)}")


if __name__ == "__main__":
    main()
