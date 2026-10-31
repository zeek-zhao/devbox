items = ["alpha", "beta"]
items.append("gamma")
record = ("job-1", "done")
fields = {"name": "Ada", "role": "admin"}
unique = {"pear", "apple", "pear"}

print(f"list: {items}")
print(f"tuple: {record}")
print(f"dict keys: {list(fields)}")
print(f"sorted set: {sorted(unique)}")
