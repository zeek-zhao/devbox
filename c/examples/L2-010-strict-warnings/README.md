

# L2-010-strict-warnings —— 把转换、遮蔽和丢弃限定符变成编译错误

## 考点

- `-Wconversion` 检查可能改变数值的隐式转换。
- `-Wshadow` 与 `-Wcast-qual` 分别发现局部变量遮蔽和丢弃 `const`。
- `-Werror` 将这些诊断提升为构建失败。

## 为什么这么写

同一份故意包含三类问题的程序在严格开关下编译；脚本需要从 stderr 找到诊断关键词才报告预期结果。

## 易错点

- 编译失败本身不足以证明目标警告生效，失败也可能来自拼写或链接错误。
- 强制转换不能消除 `const` 语义风险，反而会隐藏调用边界的修改约束。

## 运行

```bash
TAG=latest scripts/run-example.sh c L2-010-strict-warnings
```
