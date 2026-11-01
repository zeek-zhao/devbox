# L1-029-pair-tuple


## 考点
对应 KP-L1-29：函数以 `pair` 和 `tuple` 返回关联的多个值，并展示元素类型。
输出可验证通过 `std::get<>` 读取 pair，且 `std::tie` 可按元素接收 tuple 值。

## 易错点
元素下标或顺序写错会读错语义，tuple 越界下标还会编译失败；用明确类型和顺序。
避免依赖难懂的数字位置，可为复杂结果定义结构体或清晰的别名。

## 延伸
可把键与计数作为词项统计结果，并比较 pair/tuple 与具名结构体的可读性。
继续练习结构化绑定和 tuple 算法中的编译期索引约束。

## 复现
TAG=latest scripts/run-example.sh cpp L1-029-pair-tuple
