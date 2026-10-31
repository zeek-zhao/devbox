# L1-018-initialization

<!-- coverage: pending -->

## 考点
对应 KP-L1-18：观察 `std::vector<int>` 花括号列表初始化与圆括号构造的差别。
花括号得到两个元素 `10, 20`，圆括号得到十个值为 `20` 的元素。

## 易错点
`vector<int>{10, 20}` 优先匹配 `initializer_list`，不是“数量 10、值 20”。
列表初始化也会在编译期诊断窄化；例如 `int{3.7}` 不合法，本例不编译该表达式。

## 延伸
继续比较容器的列表初始化与大小/填充值构造，并检查各自的重载选择。
阅读列表初始化的窄化规则，理解哪些浮点到整数转换会被拒绝。

## 复现
TAG=latest scripts/run-example.sh cpp L1-018-initialization
