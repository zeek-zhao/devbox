class Parser:
    def parse(self, text: str) -> list[str]:
        words = text.lower().split()
        print("parse:", ",".join(words))
        return words


class Indexer:
    def index(self, words: list[str]) -> dict[str, int]:
        counts: dict[str, int] = {}
        for word in words:
            counts[word] = counts.get(word, 0) + 1
        print("index: unique =", len(counts))
        return counts


class Renderer:
    def render(self, counts: dict[str, int]) -> str:
        result = ", ".join(f"{word}={counts[word]}" for word in sorted(counts))
        print("render:", result)
        return result


class SearchFacade:
    def __init__(self):
        self._parser = Parser()
        self._indexer = Indexer()
        self._renderer = Renderer()

    def run(self, text: str) -> str:
        words = self._parser.parse(text)
        counts = self._indexer.index(words)
        return self._renderer.render(counts)


def main():
    facade = SearchFacade()
    result = facade.run("Python Patterns Python")
    assert result == "patterns=1, python=2"


if __name__ == "__main__":
    main()
