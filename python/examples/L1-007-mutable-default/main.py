def collect(value, items=[]):
    items.append(value)
    return len(items)


def collect_safely(value, items=None):
    if items is None:
        items = []
    items.append(value)
    return len(items)


print(f"shared default lengths: {collect('a')}, {collect('b')}")
print(f"fresh default lengths: {collect_safely('a')}, {collect_safely('b')}")
