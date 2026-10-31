from abc import ABC, abstractmethod


class LegacySearch:
    def lookup(self, term: str) -> str:
        return f"legacy:{term.upper()}"


class Search(ABC):
    @abstractmethod
    def search(self, term: str) -> str:
        raise NotImplementedError


class SearchAdapter(Search):
    def __init__(self, legacy: LegacySearch):
        self._legacy = legacy

    def search(self, term: str) -> str:
        return self._legacy.lookup(term)


def client(search: Search, term: str) -> str:
    return search.search(term)


def main():
    legacy = LegacySearch()
    adapted = SearchAdapter(legacy)
    direct = legacy.lookup("python")
    forwarded = client(adapted, "python")
    print("direct:", direct)
    print("adapted:", forwarded)
    print("same result:", direct == forwarded)
    print("legacy unchanged:", not hasattr(legacy, "search"))
    assert direct == forwarded
    assert isinstance(adapted, Search)
    assert not hasattr(legacy, "search")


if __name__ == "__main__":
    main()
