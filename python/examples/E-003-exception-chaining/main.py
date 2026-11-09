"""E-003 异常链：显式 from 写 __cause__，隐式写 __context__，裸 raise 原样重抛。"""


def implicit_chain():
    try:
        int("x")
    except ValueError:
        raise RuntimeError("converted")  # 没有 from：原异常只落入 __context__


def explicit_chain():
    try:
        int("x")
    except ValueError as err:
        raise RuntimeError("converted") from err  # from：原异常显式写入 __cause__


def name(obj):
    return type(obj).__name__ if obj is not None else "None"


# 裸 raise 实验：记录被捕获的对象，验证传播出去的是不是同一个实例。
captured = None
try:
    try:
        int("x")
    except ValueError as err:
        captured = err
        raise  # 裸 raise：同一异常对象继续传播，不新建包装
except ValueError as err:
    bare_line = f"bare-reraise: same-object={err is captured} cause={name(err.__cause__)}"

implicit_line = ""
try:
    implicit_chain()
except RuntimeError as err:
    implicit_line = (
        f"implicit: type={name(err)} cause={name(err.__cause__)} context={name(err.__context__)}"
    )

explicit_line = ""
try:
    explicit_chain()
except RuntimeError as err:
    explicit_line = (
        f"explicit: type={name(err)} cause={name(err.__cause__)} context={name(err.__context__)}"
    )

print(implicit_line)
print(explicit_line)
print(bare_line)
