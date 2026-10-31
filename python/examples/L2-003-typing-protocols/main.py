from typing import Generic, Optional, Protocol, TypeVar


Value_co = TypeVar("Value_co", covariant=True)
Value = TypeVar("Value")


class Source(Protocol[Value_co]):
    def read(self) -> Value_co:
        ...


class ListSource:
    def read(self) -> int:
        return 7


class Box(Generic[Value]):
    def __init__(self, value: Optional[Value]) -> None:
        self.value = value


def load(source: Source[Value]) -> Value:
    return source.read()


def maybe(value: Optional[Value]) -> Optional[Value]:
    return value


print(f"protocol value: {load(ListSource())}")
print(f"optional absent: {maybe(None) is None}")
