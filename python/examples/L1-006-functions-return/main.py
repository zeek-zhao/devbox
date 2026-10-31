def add(left, right):
    return left + right


def announce(message):
    print(f"announcement: {message}")


total = add(2, 3)
print(f"calculation result: {total}")
print(f"announcement return: {announce('ready')}")
