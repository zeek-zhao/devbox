processed = []


def generate_records():
    for record in ("alpha", "beta", "gamma"):
        processed.append(record)
        yield record.upper()


records = generate_records()
print(f"after creation: {len(processed)}")
print(f"first: {next(records)}")
print(f"after first: {len(processed)}")
print(f"remaining: {list(records)}")
print(f"after consume: {len(processed)}")
