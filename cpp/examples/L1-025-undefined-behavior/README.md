# L1-025-undefined-behavior


## 考点
对应 KP-L1-25：以检查式访问和可选值表达边界，避免执行未定义行为。
观察 `at()` 捕获到 `std::out_of_range` 且空 `optional` 的 `has_value()` 为 `false`。

## 易错点
越界 `operator[]` 不检查边界，结果不可依赖，不能用来复现或验证错误。
用 `at()` 获取定义良好的异常行为；可能缺失的结果用 `optional` 表示。

## 延伸
为外部索引增加边界检查，并让调用者区分合法值与缺失值。
使用地址消毒器辅助发现越界等错误，同时避免依赖未定义行为的表现。

## 复现
TAG=latest scripts/run-example.sh cpp L1-025-undefined-behavior
