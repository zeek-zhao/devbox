from abc import ABC, abstractmethod


class Component(ABC):
    @abstractmethod
    def render(self, depth: int = 0) -> str:
        raise NotImplementedError


class Leaf(Component):
    def __init__(self, name: str):
        self._name = name

    def render(self, depth: int = 0) -> str:
        return f"{'  ' * depth}{self._name}"


class Group(Component):
    def __init__(self, name: str):
        self._name = name
        self._children: list[Component] = []

    def add(self, child: Component):
        self._children.append(child)

    def render(self, depth: int = 0) -> str:
        lines = [f"{'  ' * depth}{self._name}/"]
        lines.extend(child.render(depth + 1) for child in self._children)
        return "\n".join(lines)


def display(component: Component):
    print(component.render())


def main():
    root = Group("root")
    root.add(Leaf("intro.txt"))
    patterns = Group("patterns")
    patterns.add(Leaf("singleton.py"))
    structural = Group("structural")
    structural.add(Leaf("composite.py"))
    patterns.add(structural)
    root.add(patterns)
    display(root)
    display(Leaf("standalone.txt"))


if __name__ == "__main__":
    main()
