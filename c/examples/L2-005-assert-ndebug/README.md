<!-- coverage: exempt 外部输入采用显式运行时检查，不能依赖可移除断言。 -->

# L2-005-assert-ndebug —— 验证 NDEBUG 会移除断言表达式

## 考点

- 默认构建执行 `assert` 中的表达式。
- 定义 `NDEBUG` 后断言宏不求值，程序状态因此不同。

## 为什么这么写

断言表达式只增加一次可观察的计数，不依赖失败断言终止进程；这样可直接比较两种编译配置的行为。

## 易错点

- 把有副作用的操作放进 `assert`，发布构建定义 `NDEBUG` 后操作会消失。
- 断言用于检查程序不变量，不应用来执行必须发生的业务逻辑。

## 运行

```bash
TAG=latest scripts/run-example.sh c L2-005-assert-ndebug
```
