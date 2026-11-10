"""E-015 反模式对照：吞错、裸 except、文本分流——每种配一个正确做法。"""

import json


def op_that_fails():
    raise RuntimeError("disk-full")


def anti_swallows():
    try:
        op_that_fails()
    except Exception:  # noqa: E722 演示反模式：不区分类型的宽吞（勿模仿）
        pass
    return "kept going"


def fixed_logs():
    try:
        op_that_fails()
    except RuntimeError as err:
        return json.dumps({"code": "INTERNAL", "message": str(err)}, sort_keys=True)
    return "unreachable"


def anti_classifies_by_text():
    try:
        op_that_fails()
    except RuntimeError as err:
        return "timeout-like" if "timeout" in str(err) else "other"
    return "unreachable"


def fixed_classifies_by_type():
    try:
        op_that_fails()
    except RuntimeError:
        return "INTERNAL"
    return "unreachable"


def anti_bare_catches_interrupt():
    try:
        raise KeyboardInterrupt  # 模拟 Ctrl-C
    except:  # noqa: E722 演示反模式：裸 except 连 BaseException 也吞（勿模仿）
        return "caught (wrong: bare except also swallows Ctrl-C)"
    return "unreachable"


def fixed_lets_interrupt_escape():
    try:
        raise KeyboardInterrupt  # 模拟 Ctrl-C
    except Exception:
        return "caught (wrong)"
    return "caught-by-broad-except (wrong)"


def main():
    print(f"anti-1: {anti_swallows()} (failure swallowed, bug invisible) -> wrong")
    print(f"fix-1: {fixed_logs()} -> logged, visible")
    print(f"anti-2: {anti_classifies_by_text()} (classified by message text) -> wrong")
    print(f"fix-2: {fixed_classifies_by_type()} (classified by type) -> stable")
    print(f"anti-3: {anti_bare_catches_interrupt()}")
    result = "unreachable"
    try:
        result = fixed_lets_interrupt_escape()
    except KeyboardInterrupt:
        result = "escaped to caller (right: Ctrl-C not swallowed)"
    print(f"fix-3: {result}")
    print("rule: never swallow silently; classify by type; let BaseException escape")


if __name__ == "__main__":
    main()
