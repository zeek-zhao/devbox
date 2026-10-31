class InvalidRecordError(Exception):
    pass


events = []
try:
    try:
        int("not-an-integer")
    except ValueError as err:
        raise InvalidRecordError("invalid record") from err
    finally:
        events.append("finally")
except InvalidRecordError as err:
    events.append(f"caught: {type(err).__name__}")
    events.append(f"cause: {type(err.__cause__).__name__}")

print("\n".join(events))
