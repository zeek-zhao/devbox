# L1-004-builtin-containers

<!-- coverage: pending -->

## 考点
对应 KP-PY-L1-04：使用 list、tuple、dict 和 set 表达不同的数据语义。
观察列表追加、元组内容、字典插入序及去重后的集合，即可判断操作符合各容器用途。
集合结果在展示前排序，保证输出顺序明确且稳定。

## 易错点
把 set 当有序容器会得到不稳定顺序；需要展示顺序时显式排序，不依赖集合遍历。
集合只保证成员去重，不承诺遍历顺序。
输出集合内容前使用 `sorted()`；需要键值映射时选用字典。

## 延伸
把输入记录放入列表、字段映射放入字典，再用集合去重并排序展示。
比较 tuple 与 list 的可变性，选择适合固定记录或动态序列的结构。

## 复现
TAG=latest scripts/run-example.sh python L1-004-builtin-containers
