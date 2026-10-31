# L1-015-context-managers


## 考点
对应 KP-PY-L1-15：通过 `__enter__` 和 `__exit__` 管理作用域资源。
正常退出和异常退出都记录清理，且未抑制的异常仍被外层捕获，即说明掌握。

## 易错点
只在正常路径手动清理，异常发生时会跳过清理并泄漏资源。
把清理统一放进 `__exit__` 或 `finally`，只有明确要抑制异常时才返回真值。

## 延伸
为输入文件封装上下文管理器，分别验证成功读取和解析失败时文件均关闭。
比较类形式与 `contextlib.contextmanager` 形式的资源管理器。

## 复现
TAG=latest scripts/run-example.sh python L1-015-context-managers
