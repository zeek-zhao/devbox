status = "global"


def shadow_status():
    status = "local"
    return status


def make_counter():
    count = 0

    def increment():
        nonlocal count
        count += 1
        return count

    return increment


counter = make_counter()
print(f"local result: {shadow_status()}")
print(f"global remains: {status}")
print(f"counter values: {counter()}, {counter()}")
