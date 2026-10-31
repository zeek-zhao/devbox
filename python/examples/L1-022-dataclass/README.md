# L1-022-dataclass


## 考点
对应 KP-PY-L1-22：观察 dataclass 自动比较、冻结字段和 `default_factory`。
实例值相等、字段列表互不共享、冻结字段拒绝赋值而内层列表仍可变，说明掌握字段工厂与冻结边界。

## 易错点
直接以 `[]` 作为默认值会让实例共享可变字段；`frozen=True` 也不会递归冻结内层对象。
用 `field(default_factory=list)` 创建独立列表，并把嵌套可变对象仍视为可变。

## 延伸
可为报表配置增加不可变的标量字段，并比较相等实例的行为。
需要深层不可变数据时，选择不可变容器或显式复制并验证嵌套结构。

## 复现
TAG=latest scripts/run-example.sh python L1-022-dataclass
