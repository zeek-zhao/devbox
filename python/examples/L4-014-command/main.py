from abc import ABC, abstractmethod
from collections import deque


class Document:
    def __init__(self):
        self.text = ""

    def append(self, text):
        self.text += text


class Command(ABC):
    @abstractmethod
    def execute(self):
        pass

    @abstractmethod
    def undo(self):
        pass


class AppendCommand(Command):
    def __init__(self, receiver, text):
        self.receiver = receiver
        self.text = text
        self._history = []

    def execute(self):
        self._history.append(self.receiver.text)
        self.receiver.append(self.text)

    def undo(self):
        if not self._history:
            raise ValueError("command has not been executed")
        self.receiver.text = self._history.pop()


class Invoker:
    def __init__(self):
        self.queue = deque()
        self.history = []

    def submit(self, command):
        self.queue.append(command)

    def execute_next(self):
        command = self.queue.popleft()
        command.execute()
        self.history.append(command)

    def undo(self):
        if not self.history:
            raise ValueError("nothing to undo")
        self.history.pop().undo()


def main():
    document = Document()
    invoker = Invoker()
    invoker.submit(AppendCommand(document, "hello"))
    invoker.submit(AppendCommand(document, " world"))
    print(f"queued: {document.text!r}")
    for _ in range(2):
        invoker.execute_next()
        print(f"execute: {document.text!r}")
    for _ in range(2):
        invoker.undo()
        print(f"undo: {document.text!r}")


if __name__ == "__main__":
    main()
