def parse_count(value: str) -> int:
    if not value.isdecimal():
        raise ValueError("count must be a non-negative integer")
    return int(value)


def internal_total(value: int) -> int:
    assert value >= 0, "internal total must be non-negative"
    return value


try:
    internal_total(-1)
except AssertionError:
    print("internal invariant: caught")

try:
    parse_count("invalid")
except ValueError:
    print("external input: rejected")
