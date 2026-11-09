"""E-012 异常消息契约：字段 + 实际值 + 期望 + 行动建议；不猜、不含敏感值。"""


class ParseError(ValueError):
    """输入解析失败：消息必须能独立指导修复。"""


def parse_amount_vague(raw):
    raise ParseError("oops")


def parse_amount_good(raw):
    raise ParseError(f"field 'amount' got {raw!r} expected integer (act: fix input)")


def contract_check(message):
    return {
        "field": "'amount'" in message,
        "value": repr("abc") in message,
        "action": "act:" in message,
    }


def show(label, message):
    checks = contract_check(message)
    print(f"{label}: field={checks['field']} value={checks['value']} action={checks['action']}")


def main():
    try:
        parse_amount_vague("abc")
    except ParseError as err:
        print(f"bad-message: {err!r} (no context: caller guesses)")
        show("contract: bad", str(err))

    try:
        parse_amount_good("abc")
    except ParseError as err:
        print(f"good-message: {err}")
        show("contract: good", str(err))

    print("rule: messages carry field, value, expectation; secrets stay out")


if __name__ == "__main__":
    main()
