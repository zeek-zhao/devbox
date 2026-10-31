from functools import wraps


def tagged(prefix):
    def decorate(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            return f"{prefix}{func(*args, **kwargs)}"

        return wrapper

    return decorate


@tagged("[audit] ")
def greet(name):
    """Return a greeting for a name."""
    return f"hello, {name}"


print(f"name: {greet.__name__}")
print(f"doc: {greet.__doc__}")
print(f"result: {greet('Ada')}")
