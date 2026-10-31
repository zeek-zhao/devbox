from abc import ABC, abstractmethod


class DataSource(ABC):
    @abstractmethod
    def read(self) -> str:
        raise NotImplementedError


class MemorySource(DataSource):
    def read(self) -> str:
        return "memory-data"


class FileSource(DataSource):
    def read(self) -> str:
        return "file-data"


class Report(ABC):
    def __init__(self, source: DataSource):
        self._source = source

    @abstractmethod
    def render(self) -> str:
        raise NotImplementedError


class PlainReport(Report):
    def render(self) -> str:
        return f"plain:{self._source.read()}"


class BracketReport(Report):
    def render(self) -> str:
        return f"[{self._source.read()}]"


def display(report: Report):
    print(report.render())


def main():
    for source in (MemorySource(), FileSource()):
        for report_type in (PlainReport, BracketReport):
            display(report_type(source))


if __name__ == "__main__":
    main()
