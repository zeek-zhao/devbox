# L1-031-fmt-formatting

<!-- coverage: pending -->

## 考点
对应 KP-GO-L1-31，固定输入分别由 `%q` 和 `%d` 格式动词生成精确文本。
输出与断言样例逐字相同，且字符串拼接结果符合预期，即可验证格式化和构造已掌握。

## 易错点
格式动词与实参类型不匹配会输出诊断文本而非期望值；按字符串、整数等类型选动词。
为格式化结果使用固定样例断言，避免仅凭肉眼判断输出。

## 延伸
为查询结果定义稳定的行格式，并用 fmt.Sprintf 构造日志或诊断消息。
进一步比较 fmt 格式化与 strings.Builder 在多段文本构造中的适用场景。

## 复现
TAG=latest scripts/run-example.sh go L1-031-fmt-formatting
