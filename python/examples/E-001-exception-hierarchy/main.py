"""E-001 异常层次与分类处理：领域异常基类 + 子类，类别决定唯一处理策略。"""


class DomainError(Exception):
    """领域异常基类：所有业务错误从这里派生，调用方按类型归类。"""


class ValidationError(DomainError):
    """输入问题：修调用方，不该重试。"""

    def __init__(self, field, value):
        self.field = field
        self.value = value
        super().__init__(f"field {field} invalid value {value}")


class TransientError(DomainError):
    """环境临时问题：可重试。"""

    def __init__(self, op, attempt):
        self.op = op
        self.attempt = attempt
        super().__init__(f"op {op} failed at attempt {attempt}")


class InternalError(DomainError):
    """程序自身 bug：快速失败。"""

    def __init__(self, component):
        self.component = component
        super().__init__(f"internal bug in {component}")


def classify(err):
    """把任意 DomainError 归入唯一类别；未知子类保守归 INTERNAL（快速失败）。"""
    if isinstance(err, ValidationError):
        return "VALIDATION"
    if isinstance(err, TransientError):
        return "TRANSIENT"
    return "INTERNAL"


def action_for(category):
    """处理策略挂在类别上：VALIDATION 修调用、TRANSIENT 重试、INTERNAL 快速失败。"""
    return {"VALIDATION": "reject-input", "TRANSIENT": "retry"}.get(category, "fail-fast")


def main():
    errs = [
        ValidationError("age", -1),
        TransientError("fetch-user", 2),
        InternalError("kv-store"),
    ]
    counts = {}
    for err in errs:
        category = classify(err)
        counts[category] = counts.get(category, 0) + 1
        print(f"{err} -> category={category} action={action_for(category)}")
    print(
        f"taxonomy types={len(errs)} "
        f"VALIDATION={counts.get('VALIDATION', 0)} "
        f"TRANSIENT={counts.get('TRANSIENT', 0)} "
        f"INTERNAL={counts.get('INTERNAL', 0)}"
    )


if __name__ == "__main__":
    main()
