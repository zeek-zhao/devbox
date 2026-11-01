# L4-015-interpreter

<!-- coverage: exempt 本项目输入是固定三列 CSV，CLI 仅选择三个固定子命令，没有用户表达式、语法树或上下文求值语言；字段解析不构成可组合的解释器语法 -->

## 考点

对应 KP-PY-L4-15：用类层次表示文法规则，对输入递归解释求值。

可观察判据：表达式节点递归求值，固定输入得到固定整数；非法输入抛指定异常。

## 为什么这样写

显式文法为 `expression := term ("+" term)*`、`term := factor ("*" factor)*`、
`factor := INTEGER | "(" expression ")"`，整数限 ASCII 非负十进制。
`Parser.expression/term/factor` 构造 `Number/Add/Multiply` 节点；
两个二元节点的 `interpret()` 行递归调用子节点，乘法优先于加法。
去掉乘法节点递归运算，前两行结果会变；去掉括号处理，第二行会抛异常。
词法错误、缺操作数、缺括号、尾随 token、空输入均真实抛 `ValueError`，
只在演示边界捕获并输出异常类型；若误接受输入，会触发断言失败。没有动态代码执行。

## 怎么跑

TAG=latest bash scripts/run-example.sh python L4-015-interpreter
