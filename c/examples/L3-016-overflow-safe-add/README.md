<!-- coverage: pending -->

# L3-016-overflow-safe-add —— 加法前检测有符号溢出

## 考点

- 在执行加法前用界限比较检测 `int` 上溢和下溢。
- 通过输出参数返回结果，并在失败时保持输出不变。

## 为什么这么写

只有确认加法不会越界才执行它，避免依赖已经发生的有符号溢出。

## 易错点

- 判断 `INT_MAX - b` 或 `INT_MIN - b` 前，要先按 `b` 的符号分支。
- 有符号溢出本身是未定义行为，不能加完再检查。

## 运行

```bash
TAG=latest scripts/run-example.sh c L3-016-overflow-safe-add
```
