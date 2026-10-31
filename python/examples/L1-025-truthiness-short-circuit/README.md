# L1-025-truthiness-short-circuit


## 考点
对应 KP-PY-L1-25：验证容器真值、`and`/`or` 返回操作数以及短路副作用。
右侧仅在逻辑需要时执行，并以 `is None` 单独识别缺失值，说明掌握真值与短路语义。

## 易错点
`if value` 会把 `0`、空容器和 `None` 都判为假，无法表达特定缺失语义。
需要判断缺失时使用 `is None`；依赖短路时让右侧副作用明确且可观察。

## 延伸
可在可选筛选条件中区分“未提供”与“提供了空值”。
为惰性默认值编写测试，确保只有缺省分支会触发计算。

## 复现
TAG=latest scripts/run-example.sh python L1-025-truthiness-short-circuit
