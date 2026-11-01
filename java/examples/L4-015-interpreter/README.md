# L4-015-interpreter

<!-- coverage: exempt 请求只含固定路径与单字段 JSON，不提供可组合表达式、查询语言或规则 DSL；JSON 字符串解码不是执行语言解释器 -->

## 考点

对应 KP-JV-L4-15：用类层次表示文法规则，对输入递归解释求值。

可观察判据：终结符与非终结符实现同一接口，固定表达式输出固定值。

## 为什么这样写

`src/Main.java` 的 `Literal`、`Variable` 是终结符，`Add`、`Multiply`
是持有两个子表达式的非终结符，全部实现返回 `int` 的 `Expression.interpret`。
非终结符中的 `left.interpret(context)`、`right.interpret(context)` 递归求值。
`main` 只构造一次 `(x + 2) * 3` 语法树，再传入两个不同上下文。
如果拆掉递归并让 `Multiply` 只返回左子树，两行结果将从 `18`、`21`
变成 `6`、`7`；如果把变量固定成常量，两次求值就不会不同。
没有 `Object` 返回值或强转，未定义变量明确抛异常。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh java L4-015-interpreter
```
