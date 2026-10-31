# L1-002-identity-equality


## 考点
对应 KP-JV-L1-02：`==` 比较对象身份，`equals` 比较内容。
两个独立创建但内容相同的字符串身份不同、内容相等且散列相同，即掌握此 KP。

## 易错点
内容查找会漏匹配，因为 `==` 比较引用身份而不是字符串值。
字符串值比较使用 `equals` 或 `Objects.equals`，后者也能安全处理空值。

## 延伸
比较自定义值对象的身份语义与内容语义，并决定何时需要覆写 `equals`。
把内容比较用于查询词匹配，而不是依赖字符串驻留。

## 复现
TAG=latest scripts/run-example.sh java L1-002-identity-equality
