from abc import ABC, abstractmethod


class State(ABC):
    @abstractmethod
    def advance(self):
        pass


class Pending(State):
    def advance(self):
        return "pending -> running", Running()


class Running(State):
    def advance(self):
        return "running -> done", Done()


class Done(State):
    def advance(self):
        return "done -> done", self


class Task:
    def __init__(self, state):
        self._state = state

    def advance(self):
        label, self._state = self._state.advance()
        return label


def main():
    task = Task(Pending())
    print(task.advance())
    print(task.advance())


if __name__ == "__main__":
    main()
