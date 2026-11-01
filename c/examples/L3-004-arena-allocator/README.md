<!-- coverage: pending -->

# L3-004-arena-allocator —— 用 bump 指针完成区域分配

## 考点

- 在一个大块内存上对齐分配多个对象。
- 通过一次释放回收整个区域，并记录分配次数和占用字节。

## 为什么这么写

分配只推进游标，不对 arena 内部的对象单独 `free`；程序最后仅释放原始大块。

## 易错点

- 每次分配都要把偏移向上取整到对象对齐要求。
- 必须先检查容量，避免游标越过 arena 末尾。

## 运行

```bash
TAG=latest scripts/run-example.sh c L3-004-arena-allocator
```
