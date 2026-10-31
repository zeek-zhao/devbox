class RecordIterator:
    def __init__(self, records):
        self._records = iter(records)

    def __iter__(self):
        return self

    def __next__(self):
        try:
            return next(self._records)
        except StopIteration:
            raise


iterator = RecordIterator([None, "record"])
print(f"items: {list(iterator)}")
try:
    next(iterator)
except StopIteration:
    print("exhausted: StopIteration")
