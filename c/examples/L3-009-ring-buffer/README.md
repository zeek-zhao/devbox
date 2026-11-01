<!-- coverage: pending -->

# L3-009-ring-buffer —— 用计数区分环形缓冲区的满与空

## 考点

- 用固定容量环保存和读取数据。
- 写满后拒绝数据，并在读空后报告空状态。

## 为什么这么写

单独的 `head == tail` 无法区分满和空，因此额外保存元素计数，容量 3 可以全部使用。

## 易错点

- 每次推进读写位置都必须对容量取模。
- 缓冲区满时不能覆盖尚未读取的元素。

## 运行

```bash
TAG=latest scripts/run-example.sh c L3-009-ring-buffer
```
