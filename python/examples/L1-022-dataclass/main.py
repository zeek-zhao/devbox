from dataclasses import FrozenInstanceError, dataclass, field


@dataclass(frozen=True)
class ReportConfig:
    labels: list[str] = field(default_factory=list)


first = ReportConfig()
second = ReportConfig()
print("equal defaults:", first == second)
print("independent lists:", first.labels is not second.labels)

try:
    first.labels = ["urgent"]
except FrozenInstanceError:
    print("field assignment rejected: true")

first.labels.append("urgent")
print("nested list remains mutable:", first.labels)
