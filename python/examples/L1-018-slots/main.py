class Record:
    __slots__ = ("name",)


class SlottedRecord(Record):
    __slots__ = ("value",)


class DictionaryRecord(Record):
    __slots__ = ("__dict__",)


restricted = SlottedRecord()
restricted.name = "row"
restricted.value = 1
try:
    restricted.extra = True
except AttributeError:
    print("slotted extra rejected: True")

extended = DictionaryRecord()
extended.name = "row"
extended.extra = True
print(f"subclass has dict: {hasattr(extended, '__dict__')}")
print(f"subclass extra accepted: {extended.extra}")
