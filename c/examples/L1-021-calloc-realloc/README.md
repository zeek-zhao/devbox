<!-- coverage: pending -->

# L1-021-calloc-realloc —— 验证清零分配与 realloc 失败语义

## 考点

- `calloc` 为数组元素提供全零的初始字节。
- `realloc` 失败返回空指针时，原分配仍然有效，必须用临时指针接收结果。

## 为什么这么写

先打印 `calloc` 数组的和，再用 `SIZE_MAX` 请求不可能满足的扩容；失败后仍读取原数组，实际验证原指针没有丢失。

## 易错点

- 不要写 `values = realloc(values, size)`：失败时会覆盖唯一的原指针并泄漏内存。
- 只有扩容成功后才能用返回的新指针替换旧指针；本例的失败路径继续释放原指针。

## 运行

```bash
TAG=latest scripts/run-example.sh c L1-021-calloc-realloc
```
