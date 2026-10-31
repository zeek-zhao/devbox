from abc import ABC, abstractmethod


class SortStrategy(ABC):
    @abstractmethod
    def sort(self, words):
        pass


class AlphabeticalSort(SortStrategy):
    def sort(self, words):
        return sorted(words)


class LengthSort(SortStrategy):
    def sort(self, words):
        return sorted(words, key=len)


class WordSorter:
    def __init__(self, strategy):
        self._strategy = strategy

    def set_strategy(self, strategy):
        self._strategy = strategy

    def sort(self, words):
        return self._strategy.sort(words)


def main():
    words = ["pear", "fig", "apple", "kiwi"]
    sorter = WordSorter(AlphabeticalSort())
    print(f"alphabetical: {sorter.sort(words)}")
    sorter.set_strategy(LengthSort())
    print(f"length: {sorter.sort(words)}")
    print(f"input unchanged: {words}")


if __name__ == "__main__":
    main()
