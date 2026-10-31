# L1-028-sorting-key

<!-- coverage: pending -->

## 考点
对应 KP-PY-L1-28：用显式 `key` 排序，并观察 `sorted()` 的稳定性与输入保留。
同键记录保持原有先后、原列表不变，说明理解排序键、稳定排序和非原地排序。

## 易错点
`list.sort()` 会原地修改列表并返回 `None`，把它的返回值当排序结果会丢失数据。
需要保留输入时使用带显式 `key` 的 `sorted()`；只有想原地修改时才调用 `sort()`。

## 延伸
可以为报表记录按多个字段构造排序键，并验证同键记录的稳定顺序。
比较反向排序与复合键，确保排序规则直接对应业务优先级。

## 复现
TAG=latest scripts/run-example.sh python L1-028-sorting-key
