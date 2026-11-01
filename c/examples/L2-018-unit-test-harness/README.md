<!-- coverage: pending -->

# L2-018-unit-test-harness —— 用宏搭建可定位失败行的断言测试

## 考点

- 自定义 `TEST_ASSERT` 宏把条件、断言次数和调用行号传给测试辅助函数。
- 运行三个真实检查，全部通过后才输出通过数量。

## 为什么这么写

测试逻辑不依赖外部框架；失败时辅助函数向 stderr 报告源文件与行号并返回失败退出码。

## 易错点

- 宏参数未放在 `do { ... } while (0)` 中时，在条件语句等上下文可能展开错误。
- 只打印固定的通过数量而不累计断言，会让断言未执行也产生假阳性。

## 运行

```bash
TAG=latest scripts/run-example.sh c L2-018-unit-test-harness
```
