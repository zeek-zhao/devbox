"""E-002 except 匹配顺序：具体类型在前，宽兜底在后；同级类型用元组一次捕获。"""


def parse(text):
    return int(text)


def lookup(key):
    return {"a": 1}[key]


def run_fallback():
    raise RuntimeError("boom")


def handle_parse(text):
    try:
        return f"got {parse(text)}"
    except ValueError as err:  # 具体类型在前：int() 对非法文本只抛 ValueError
        return f"ValueError: {err}"


def handle_lookup(key):
    try:
        return f"got {lookup(key)}"
    except (TypeError, KeyError) as err:  # 同级类型用元组一次捕获
        return f"{type(err).__name__}: {err}"


def handle_anything():
    try:
        run_fallback()
    except Exception as err:  # 宽兜底放最后：前面必须先给具体类型机会
        return f"Exception: {type(err).__name__}: {err}"


print(f"specific-first: {handle_parse('x')}")
print(f"tuple-catch: {handle_lookup('missing')}")
print(f"fallback-last: {handle_anything()}")
print("order-rule: except clauses are tried top-down, subclass handlers go first")
