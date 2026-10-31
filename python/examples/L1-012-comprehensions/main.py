def double_and_record(value, records):
    records.append(value)
    return value * 2


values = [1, 2, 3]
list_records = []
eager = [double_and_record(value, list_records) for value in values]
print(f"list: {eager}")
print(f"list records: {list_records}")

generator_records = []
lazy = (double_and_record(value, generator_records) for value in values)
print(f"generator before next: {generator_records}")
print(f"first: {next(lazy)}")
print(f"generator after next: {generator_records}")
print(f"remaining: {list(lazy)}")
print(f"generator after consume: {generator_records}")
