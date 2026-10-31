from abc import ABC, abstractmethod


class QueryService(ABC):
    @abstractmethod
    def query(self, term: str) -> str:
        raise NotImplementedError


class RealQuery(QueryService):
    def query(self, term: str) -> str:
        return f"result:{term.upper()}"


class CountingProxy(QueryService):
    def __init__(self, target: QueryService):
        self._target = target
        self.calls = 0

    def query(self, term: str) -> str:
        self.calls += 1
        return self._target.query(term)


def client(service: QueryService, term: str) -> str:
    return service.query(term)


def main():
    target = RealQuery()
    proxy = CountingProxy(target)
    print("calls before:", proxy.calls)
    for term in ("python", "patterns", "python"):
        result = client(proxy, term)
        print(result)
        assert result == client(target, term)
    print("calls after:", proxy.calls)
    print("shared interface:", isinstance(target, QueryService) and isinstance(proxy, QueryService))
    assert proxy.calls == 3


if __name__ == "__main__":
    main()
