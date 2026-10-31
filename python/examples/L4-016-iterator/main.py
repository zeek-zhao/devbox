class TokenIterator:
    def __init__(self, tokens):
        self._tokens = tokens
        self._position = 0

    def __iter__(self):
        return self

    def __next__(self):
        if self._position >= len(self._tokens):
            raise StopIteration
        token = self._tokens[self._position]
        self._position += 1
        return token


class TokenIndex:
    def __init__(self, tokens):
        self._tokens = tuple(tokens)

    def __iter__(self):
        return TokenIterator(self._tokens)


def main():
    index = TokenIndex(("alpha", "beta", "gamma"))
    iterator = iter(index)
    print(f"iter(it) is it: {iter(iterator) is iterator}")
    print(f"tokens: {list(iterator)}")
    for _ in range(2):
        try:
            next(iterator)
        except StopIteration as error:
            print(f"exhausted: {type(error).__name__}")
        else:
            raise AssertionError("exhausted iterator returned a value")
    print(f"fresh iterator: {list(index)}")


if __name__ == "__main__":
    main()
