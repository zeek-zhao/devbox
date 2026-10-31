# L1-019-overload-resolution

<!-- coverage: pending -->

## 考点
对应 KP-L1-19：通过返回标签观察 `int`、`long`、`double` 与模板候选的胜出情况。
精确类型分别选中对应非模板重载，`short` 精确匹配模板而非转换到其他类型。

## 易错点
候选函数会按可行性和转换序列比较，模板也可能因精确匹配而胜出。
用实际参数类型预测最佳转换，并为每个重载返回可观察的唯一标签。

## 延伸
可继续试验 `const` 引用、用户定义转换和限定转换对候选集的影响。
研究歧义调用的形成条件，并通过显式类型或重载调整消除歧义。

## 复现
TAG=latest scripts/run-example.sh cpp L1-019-overload-resolution
