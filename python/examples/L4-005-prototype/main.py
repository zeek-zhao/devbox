from copy import deepcopy


class IndexPrototype:
    constructions = 0

    def __init__(self, groups: list[list[str]]):
        type(self).constructions += 1
        self.groups = groups

    def clone(self) -> "IndexPrototype":
        return deepcopy(self)


def main():
    original = IndexPrototype([["python"], ["patterns"]])
    cloned = original.clone()
    print("different objects:", original is not cloned)
    print("independent inner lists:", original.groups[0] is not cloned.groups[0])
    cloned.groups[0].append("copy-only")
    original.groups[1].append("original-only")
    print("original:", original.groups)
    print("clone:", cloned.groups)
    print("constructor calls:", IndexPrototype.constructions)
    assert original.groups == [["python"], ["patterns", "original-only"]]
    assert cloned.groups == [["python", "copy-only"], ["patterns"]]
    assert IndexPrototype.constructions == 1


if __name__ == "__main__":
    main()
