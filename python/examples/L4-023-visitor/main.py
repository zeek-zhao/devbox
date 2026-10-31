from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass


class Visitor(ABC):
    @abstractmethod
    def visit_number(self, node: NumberNode) -> str:
        pass

    @abstractmethod
    def visit_text(self, node: TextNode) -> str:
        pass


class Node(ABC):
    @abstractmethod
    def accept(self, visitor: Visitor) -> str:
        pass


@dataclass(frozen=True)
class NumberNode(Node):
    value: int

    def accept(self, visitor: Visitor) -> str:
        return visitor.visit_number(self)


@dataclass(frozen=True)
class TextNode(Node):
    value: str

    def accept(self, visitor: Visitor) -> str:
        return visitor.visit_text(self)


class RenderVisitor(Visitor):
    def visit_number(self, node: NumberNode) -> str:
        return f"render number: {node.value}"

    def visit_text(self, node: TextNode) -> str:
        return f"render text: {node.value!r}"


class MeasureVisitor(Visitor):
    def visit_number(self, node: NumberNode) -> str:
        return f"measure number: digits={len(str(abs(node.value)))}"

    def visit_text(self, node: TextNode) -> str:
        return f"measure text: length={len(node.value)}"


def main():
    nodes: tuple[Node, ...] = (NumberNode(42), TextNode("python"))
    visitors: tuple[Visitor, ...] = (RenderVisitor(), MeasureVisitor())
    for visitor in visitors:
        for node in nodes:
            print(node.accept(visitor))


if __name__ == "__main__":
    main()
