from enum import Enum


class TaskState(Enum):
    QUEUED = "queued"
    RUNNING = "running"
    COMPLETE = "complete"


def parse_state(value):
    try:
        return TaskState(value)
    except ValueError:
        return None


state = TaskState.RUNNING
print("same member:", state is TaskState.RUNNING)
print("string is member:", "running" == state)
print("name:", state.name)
print("value:", state.value)
print("boundary conversion:", parse_state("complete") is TaskState.COMPLETE)
print("invalid value rejected:", parse_state("unknown") is None)
