# L1-023-collections

<!-- coverage: pending -->

## 考点
对应 KP-PY-L1-23：使用 `Counter`、`defaultdict` 和 `deque` 处理固定数据。
频次稳定、读取缺失分组后键确实新增、双端队列按预期进出，说明理解这些容器的行为。

## 易错点
`defaultdict` 读取缺失键会创建并写入默认值，而 `Counter` 对缺失计数返回零但不插入该键。
读取前先确认容器的访问副作用；展示映射内容时按键排序。

## 延伸
可将分组容器用于报表行归类，并用 deque 实现固定长度滑动窗口。
对窗口边界和空容器分别增加断言，确保两端操作保持预期顺序。

## 复现
TAG=latest scripts/run-example.sh python L1-023-collections
