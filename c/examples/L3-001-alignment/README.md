<!-- coverage: pending -->

# L3-001-alignment —— 验证类型与对象的内存对齐

## 考点

- 使用 `_Alignof` 查询类型要求的对齐。
- 使用 `_Alignas(16)` 声明更强对齐的对象，并验证真实地址。

## 为什么这么写

`_Alignof` 描述类型的要求，取模检查则直接验证实际对象地址；两者分别覆盖类型和实例。

## 易错点

- 只打印 `_Alignof` 不能证明特定对象真的满足显式对齐。
- 不要输出地址本身，地址会随进程变化。

## 运行

```bash
TAG=latest scripts/run-example.sh c L3-001-alignment
```
