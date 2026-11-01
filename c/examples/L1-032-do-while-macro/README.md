<!-- coverage: pending -->

# L1-032-do-while-macro —— 把多语句宏包装成单条语句

## 考点

- 裸 `if` 宏会改变调用点 `if/else` 的语法结合关系。
- `do { ... } while (0)` 让多语句宏在调用处表现为单条语句。

## 为什么这么写

外层条件为真、宏内条件为假；裸宏让 `else` 错误地绑定到宏内 `if` 并输出 `broken=outer-else`，安全宏则保持外层分支结构。
只对这段故意错误的裸宏代码局部屏蔽 GCC 的 `-Wdangling-else`，否则 `-Werror` 会在运行前终止；其余警告仍按错误处理。

## 易错点

- 宏调用后面仍应写分号；`do-while` 包装可自然容纳这个分号。
- `else` 绑定最近的未匹配 `if`，不是按缩进或视觉布局决定。

## 运行

```bash
TAG=latest scripts/run-example.sh c L1-032-do-while-macro
```
