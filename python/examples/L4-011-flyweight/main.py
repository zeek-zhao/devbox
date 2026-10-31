from dataclasses import dataclass
from typing import ClassVar


@dataclass(frozen=True)
class Token:
    text: str
    constructions: ClassVar[int] = 0

    def __post_init__(self):
        type(self).constructions += 1

    def render(self, position: int) -> str:
        return f"{self.text}@{position}"


class TokenFactory:
    def __init__(self):
        self._cache: dict[str, Token] = {}

    def get(self, key: str) -> Token:
        if key not in self._cache:
            self._cache[key] = Token(key)
        return self._cache[key]


def main():
    factory = TokenFactory()
    keys = ["python", "patterns", "python", "patterns"]
    tokens = [factory.get(key) for key in keys]
    print("same python:", tokens[0] is tokens[2])
    print("same patterns:", tokens[1] is tokens[3])
    print("different keys:", tokens[0] is not tokens[1])
    for position, token in enumerate(tokens):
        print(token.render(position))
    print("constructions:", Token.constructions)
    print("distinct keys:", len(set(keys)))
    assert tokens[0] is tokens[2]
    assert tokens[1] is tokens[3]
    assert Token.constructions == len(set(keys))


if __name__ == "__main__":
    main()
