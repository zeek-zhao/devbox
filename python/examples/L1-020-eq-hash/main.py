class DimensionKey:
    def __init__(self, name, value):
        self.name = name
        self.value = value

    def __eq__(self, other):
        if not isinstance(other, DimensionKey):
            return NotImplemented
        return (self.name, self.value) == (other.name, other.value)

    def __hash__(self):
        return hash((self.name, self.value))


class MutableRecord:
    def __init__(self, value):
        self.value = value

    def __eq__(self, other):
        if not isinstance(other, MutableRecord):
            return NotImplemented
        return self.value == other.value


first = DimensionKey("region", "north")
equivalent = DimensionKey("region", "north")
keys = {first, equivalent}
lookup = {first: "matched"}
print(f"equal: {first == equivalent}")
print(f"set size: {len(keys)}")
print(f"dict lookup: {lookup[equivalent]}")
try:
    hash(MutableRecord("north"))
except TypeError:
    print("mutable record hashable: False")
