from dataclasses import dataclass, is_dataclass
from typing import Self


@dataclass(frozen=True)
class Query:
    source: str
    limit: int = 10
    fields: tuple[str, ...] = ()


class QueryBuilder:
    def __init__(self):
        self._source: str | None = None
        self._limit = 10
        self._fields: tuple[str, ...] = ()

    def source(self, value: str) -> Self:
        self._source = value
        return self

    def limit(self, value: int) -> Self:
        self._limit = value
        return self

    def fields(self, *values: str) -> Self:
        self._fields = values
        return self

    def build(self) -> Query:
        if not self._source:
            raise ValueError("source is required")
        return Query(self._source, self._limit, self._fields)


def main():
    builder = QueryBuilder()
    source_step = builder.source("books")
    limit_step = source_step.limit(2)
    fields_step = limit_step.fields("title", "author")
    print("steps return self:", source_step is limit_step is fields_step is builder)
    query = fields_step.build()
    print("dataclass instance:", isinstance(query, Query) and is_dataclass(query))
    print("query:", query.source, query.limit, ",".join(query.fields))
    builder.limit(5)
    print("built result unchanged:", query.limit)
    assert source_step is limit_step is fields_step is builder
    assert query == Query("books", 2, ("title", "author"))
    try:
        QueryBuilder().limit(2).build()
    except ValueError as error:
        print("missing field:", type(error).__name__, str(error))
    else:
        raise AssertionError("build must reject a missing source")


if __name__ == "__main__":
    main()
