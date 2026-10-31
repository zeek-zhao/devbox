from collections.abc import Callable


class Subject:
    def __init__(self):
        self._version = 0
        self._observers: list[Callable[[int], None]] = []

    def register(self, callback):
        if callback not in self._observers:
            self._observers.append(callback)

    def unregister(self, callback):
        self._observers.remove(callback)

    def update(self):
        self._version += 1
        for callback in tuple(self._observers):
            callback(self._version)


def invalidate_cache(version):
    print(f"cache: version={version}")


def refresh_view(version):
    print(f"view: version={version}")


def main():
    subject = Subject()
    subject.register(invalidate_cache)
    subject.register(refresh_view)
    subject.update()
    subject.unregister(invalidate_cache)
    subject.update()


if __name__ == "__main__":
    main()
