first = [1, 2]
second = [1, 2]
print(f"equal values: {first == second}")
print(f"same object: {first is second}")

record = ("item", [1])
record[1].append(2)
print(f"tuple member after append: {record[1]}")
print(f"none singleton: {None is None}")
