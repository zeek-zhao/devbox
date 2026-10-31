from abc import ABC, abstractmethod


class Handler(ABC):
    def __init__(self, next_handler=None):
        self.next_handler = next_handler

    @abstractmethod
    def accepts(self, level):
        pass

    def handle(self, level):
        if self.accepts(level):
            return f"handled: {type(self).__name__}"
        if self.next_handler is not None:
            return self.next_handler.handle(level)
        return "default: unhandled"


class InfoHandler(Handler):
    def accepts(self, level):
        return level == "info"


class WarningHandler(Handler):
    def accepts(self, level):
        return level == "warning"


class ErrorHandler(Handler):
    def accepts(self, level):
        return level == "error"


def main():
    chain = InfoHandler(WarningHandler(ErrorHandler()))
    for level in ("info", "warning", "error", "unknown"):
        print(chain.handle(level))


if __name__ == "__main__":
    main()
