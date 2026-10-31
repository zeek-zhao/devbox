from abc import ABC, abstractmethod
from dataclasses import dataclass
import re


class Expression(ABC):
    @abstractmethod
    def interpret(self):
        pass


@dataclass(frozen=True)
class Number(Expression):
    value: int

    def interpret(self):
        return self.value


@dataclass(frozen=True)
class Add(Expression):
    left: Expression
    right: Expression

    def interpret(self):
        return self.left.interpret() + self.right.interpret()


@dataclass(frozen=True)
class Multiply(Expression):
    left: Expression
    right: Expression

    def interpret(self):
        return self.left.interpret() * self.right.interpret()


class Parser:
    def __init__(self, source):
        self.tokens = []
        position = 0
        while position < len(source):
            if source[position].isspace():
                position += 1
                continue
            match = re.match(r"[0-9]+|[+*()]", source[position:])
            if match is None:
                raise ValueError(f"invalid character at {position}")
            self.tokens.append(match.group())
            position += len(match.group())
        self.position = 0

    def peek(self):
        if self.position == len(self.tokens):
            return None
        return self.tokens[self.position]

    def take(self):
        token = self.peek()
        if token is None:
            raise ValueError("expected a token")
        self.position += 1
        return token

    def parse(self):
        expression = self.expression()
        if self.peek() is not None:
            raise ValueError("unexpected trailing token")
        return expression

    def expression(self):
        node = self.term()
        while self.peek() == "+":
            self.take()
            node = Add(node, self.term())
        return node

    def term(self):
        node = self.factor()
        while self.peek() == "*":
            self.take()
            node = Multiply(node, self.factor())
        return node

    def factor(self):
        token = self.take()
        if token == "(":
            node = self.expression()
            if self.take() != ")":
                raise ValueError("expected closing parenthesis")
            return node
        if token.isdecimal():
            return Number(int(token))
        raise ValueError("expected integer or parenthesis")


def main():
    for source in ("2 + 3 * 4", "(2 + 3) * 4"):
        print(f"{source} = {Parser(source).parse().interpret()}")
    for source in ("2 +", "(2 + 3", "2 3", "2 / 3", ""):
        try:
            Parser(source).parse()
        except ValueError as error:
            print(f"invalid {source!r}: {type(error).__name__}")
        else:
            raise AssertionError("invalid expression was accepted")


if __name__ == "__main__":
    main()
