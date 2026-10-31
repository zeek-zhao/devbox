from copy import deepcopy

original = [["a"], ["b"]]
shallow = original[:]
deep = deepcopy(original)

shallow[0].append("shared")
deep[1].append("independent")

print(f"original: {original}")
print(f"shallow: {shallow}")
print(f"deep: {deep}")
