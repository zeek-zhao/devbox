from abc import ABC, abstractmethod


class Product(ABC):
    @abstractmethod
    def name(self) -> str:
        raise NotImplementedError


class JsonParser(Product):
    def name(self) -> str:
        return "json"


class CsvParser(Product):
    def name(self) -> str:
        return "csv"


class ParserFactory(ABC):
    @abstractmethod
    def create(self) -> Product:
        raise NotImplementedError


class JsonFactory(ParserFactory):
    def create(self) -> Product:
        return JsonParser()


class CsvFactory(ParserFactory):
    def create(self) -> Product:
        return CsvParser()


def describe(factory: ParserFactory) -> Product:
    product = factory.create()
    print("abstract product:", isinstance(product, Product))
    print("name:", product.name())
    assert isinstance(product, Product)
    return product


def main():
    first = describe(JsonFactory())
    second = describe(CsvFactory())
    print("json instance:", isinstance(first, JsonParser))
    print("csv instance:", isinstance(second, CsvParser))
    print("different types:", type(first) is not type(second))
    assert isinstance(first, JsonParser)
    assert isinstance(second, CsvParser)


if __name__ == "__main__":
    main()
