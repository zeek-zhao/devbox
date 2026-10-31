record = ("item-7", "north", "priority", "open")
identifier, *details, status = record
print("identifier:", identifier)
print("details:", details)
print("status:", status)

defaults = {"format": "text", "limit": 10}
overrides = {"limit": 5}
options = {**defaults, **overrides}
print("options:", sorted(options.items()))
