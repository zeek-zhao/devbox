events = []


class ManagedResource:
    def __enter__(self):
        events.append("enter")
        return self

    def __exit__(self, exc_type, exc, traceback):
        events.append(f"exit: {exc_type.__name__ if exc_type else 'normal'}")
        return False


with ManagedResource():
    events.append("normal body")
print(f"normal: {events}")

events.clear()
try:
    with ManagedResource():
        events.append("exception body")
        raise ValueError("invalid record")
except ValueError:
    events.append("caught: ValueError")
print(f"exception: {events}")
