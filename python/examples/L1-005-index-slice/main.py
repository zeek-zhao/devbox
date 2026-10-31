sequence = "abcdef"
print(f"slice 1:4: {sequence[1:4]}")
print(f"last item: {sequence[-1]}")
print(f"reverse: {sequence[::-1]}")
print(f"out-of-range slice: {sequence[10:20]!r}")

try:
    sequence[10]
except IndexError:
    print("out-of-range index raises: True")
