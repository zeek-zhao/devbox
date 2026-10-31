<!-- coverage: pending -->

# L3-022-error-code-design —— 用枚举错误码分派不同失败路径

## 考点

- 通过 `enum` 表达成功、无效输入和未找到等不同结果。
- 调用方使用 `switch` 分别处理每条路径。

## 为什么这么写

错误码属于函数接口语义，不与 `errno` 或通用的 `-1` 混用。

## 易错点

- 检查错误码而不是把所有非零结果当成同一种错误。
- `switch` 应覆盖每个枚举值并保留未知值的兜底分支。

## 运行

```bash
TAG=latest scripts/run-example.sh c L3-022-error-code-design
```
