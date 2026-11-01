<!-- coverage: exempt 固定槽位池不需要可变尾部对象布局。 -->

# L1-026-flexible-array-member —— 一次分配结构体与尾随数据

## 考点

- 柔性数组成员允许结构体尾部携带长度可变的数据。
- 结构体与数据区可以通过一次动态分配得到连续存储。

## 为什么这么写

分配大小明确包含 `sizeof *buffer`、字符数和终止符，再用 `memcpy` 填入数据并输出长度与内容，实际使用尾随空间。

## 易错点

- `sizeof(struct buf)` 不包含柔性数组成员所需的元素存储。
- 复制字符串时还需要为结尾的 `'\0'` 留出一个字节。

## 运行

```bash
TAG=latest scripts/run-example.sh c L1-026-flexible-array-member
```
