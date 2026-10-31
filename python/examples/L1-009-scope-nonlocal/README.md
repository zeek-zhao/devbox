# L1-009-scope-nonlocal

<!-- coverage: pending -->

## 考点
对应 KP-PY-L1-09：观察局部名称遮蔽外层名称，以及 `nonlocal` 更新外层函数状态。
局部赋值返回新值但不改变全局名称；嵌套计数器两次调用分别返回递增后的值。
看到这两种结果即可确认理解名称查找范围与赋值作用域。

## 易错点
函数内赋值会使名称默认为局部，读取前可能触发 `UnboundLocalError`；用参数或 `nonlocal` 明确状态来源。
局部名称与同名全局名称不是同一绑定，`nonlocal` 则显式指向最近的外层函数名称。
需要更新闭包状态时声明 `nonlocal`；避免在赋值前读取尚未绑定的局部名称。

## 延伸
将 `nonlocal` 计数器用于报表构建中的局部状态，并测试多次调用的状态变化。
进一步区分 `global` 与 `nonlocal`，明确状态是否属于模块还是外层函数。

## 复现
TAG=latest scripts/run-example.sh python L1-009-scope-nonlocal
