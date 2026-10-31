calls = []


def fallback():
    calls.append("called")
    return "fallback"


empty = []
nonempty = ["entry"]
print("empty list is false:", not empty)
print("non-empty list is true:", bool(nonempty))
print("and result:", empty and fallback())
print("or result:", "ready" or fallback())
print("right-side calls:", len(calls))

for value in (0, None):
    print(f"{value!r} is missing:", value is None)
