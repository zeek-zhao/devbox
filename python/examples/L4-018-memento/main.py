from dataclasses import FrozenInstanceError, dataclass


@dataclass(frozen=True)
class Memento:
    query: str
    tags: tuple[str, ...]


class QuerySession:
    def __init__(self, query, tags):
        self._query = query
        self._tags = list(tags)

    def save(self):
        return Memento(self._query, tuple(self._tags))

    def restore(self, memento):
        self._query = memento.query
        self._tags = list(memento.tags)

    def edit(self, query, tag):
        self._query = query
        self._tags.append(tag)

    def describe(self):
        return f"query={self._query!r}, tags={self._tags}"


class History:
    def __init__(self):
        self._snapshots = []

    def checkpoint(self, session):
        snapshot = session.save()
        self._snapshots.append(snapshot)
        return snapshot

    def undo(self, session):
        if not self._snapshots:
            raise ValueError("no checkpoint")
        session.restore(self._snapshots.pop())


def main():
    session = QuerySession("python", ["stdlib"])
    history = History()
    snapshot = history.checkpoint(session)
    print(f"saved: {session.describe()}")
    session.edit("patterns", "behavioral")
    print(f"edited: {session.describe()}")
    try:
        snapshot.query = "tampered"
    except FrozenInstanceError as error:
        print(f"readonly: {type(error).__name__}")
    else:
        raise AssertionError("snapshot was writable")
    history.undo(session)
    print(f"restored: {session.describe()}")
    print(f"matches snapshot: {session.save() == snapshot}")
    session.edit("next", "new")
    print(f"snapshot tags after edit: {snapshot.tags}")


if __name__ == "__main__":
    main()
