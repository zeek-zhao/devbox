from abc import ABC, abstractmethod


class Message(ABC):
    @abstractmethod
    def render(self) -> str:
        raise NotImplementedError


class Text(Message):
    def __init__(self, text: str):
        self._text = text

    def render(self) -> str:
        return self._text


class MessageDecorator(Message):
    def __init__(self, wrapped: Message):
        self._wrapped = wrapped

    def render(self) -> str:
        return self._wrapped.render()


class Brackets(MessageDecorator):
    def render(self) -> str:
        return f"[{super().render()}]"


class Prefix(MessageDecorator):
    def render(self) -> str:
        return f"audit:{super().render()}"


def display(message: Message):
    print(message.render())


def main():
    text = Text("python")
    display(text)
    display(Brackets(text))
    display(Prefix(Brackets(text)))
    display(Brackets(Prefix(text)))
    display(text)


if __name__ == "__main__":
    main()
