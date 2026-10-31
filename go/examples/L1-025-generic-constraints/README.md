# L1-025-generic-constraints

<!-- coverage: pending -->

## 考点
对应 KP-GO-L1-25：约束 interface 的整数类型集允许函数体执行加法。
看到 int 求和为 10、int64 求和为 18，并且 string rejected 为 true，即掌握约束准入。
拒绝事实由 go/types 检查内存源码得到，不把无法编译的调用放入实际构建文件。

## 易错点
约束需列出函数体使用的操作；过宽约束如 any 不保证支持加法，会导致编译失败。
按实际操作声明类型集或方法集；本例用 ~int 与 ~int64 限定数值统计输入，排除字符串。

## 延伸
在索引统计中用相同约束支持不同整数计数类型。
尝试以 int 为底层类型的具名计数类型，验证 ~ 表示的底层类型准入规则。

## 复现
TAG=latest scripts/run-example.sh go L1-025-generic-constraints
