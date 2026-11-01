<!-- coverage: exempt 协议缓冲区按安全上限固定，不需要扩容数组。 -->

# L3-006-dynamic-array —— 观察动态数组的倍增扩容

## 考点

- 从零容量开始 push，并按需扩容保存元素。
- 输出扩容容量序列，验证容量翻倍策略。

## 为什么这么写

只在容量不足时 `realloc`，将 1000 次插入的扩容次数控制在对数级。

## 易错点

- `realloc` 失败时原指针仍有效，不能直接覆盖唯一指针。
- 计算容量乘二前要检查整数溢出。

## 运行

```bash
TAG=latest scripts/run-example.sh c L3-006-dynamic-array
```
