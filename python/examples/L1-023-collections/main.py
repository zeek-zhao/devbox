from collections import Counter, defaultdict, deque


counts = Counter(["pear", "apple", "pear", "plum"])
print("counts:", sorted(counts.items()))
print("Counter missing count:", counts["missing"])
print("Counter missing inserted:", "missing" in counts)

groups = defaultdict(list)
groups["fruit"].append("pear")
print("defaultdict keys before:", sorted(groups))
print("missing group:", groups["vegetable"])
print("defaultdict keys after:", sorted(groups))

items = deque(["middle"])
items.appendleft("left")
items.append("right")
print("deque left pop:", items.popleft())
print("deque right pop:", items.pop())
print("deque remaining:", list(items))
