"""E-009 错误聚合：一次收集全部校验错误再统一上报，而不是首错即停。"""

MAX_AGE = 150

RECORDS = [
    {"name": "alice", "age": 30},
    {"name": "", "age": -1},
    {"name": "bob", "age": 200},
    {},
]


def validate(record):
    """返回该记录的全部错误；不抛异常，让调用方决定聚合策略。"""
    errors = []
    if "name" not in record:
        errors.append("field-missing:name")
    elif not record["name"]:
        errors.append("name-empty")
    if "age" not in record:
        errors.append("field-missing:age")
    else:
        age = record["age"]
        if age < 0:
            errors.append("age-negative")
        if age > MAX_AGE:
            errors.append("age-out-of-range")
    return errors


def main():
    bad = 0
    total_errors = 0
    for idx, record in enumerate(RECORDS, start=1):
        errors = validate(record)
        if not errors:
            print(f"record {idx}: ok")
            continue
        bad += 1
        total_errors += len(errors)
        print(f"record {idx}: errors={len(errors)} {' '.join(errors)}")
    print(f"aggregate: bad={bad} errors={total_errors} -> report all, then reject")


if __name__ == "__main__":
    main()
