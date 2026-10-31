<!-- coverage: pending -->

# L3-017-bsearch-variants —— 区分 lower_bound、upper_bound 与精确查找

## 考点

- 在重复元素数组中定位第一个不小于目标的位置。
- 定位第一个大于目标的位置，并据此实现精确查找。

## 为什么这么写

三种查询共用半开区间 `[lo, hi)`，因此边界值 `size` 可表示「未找到插入点」。

## 易错点

- `mid` 写成 `lo + (hi - lo) / 2`，避免 `lo + hi` 溢出。
- 右边界测试 `< target` 与 `<= target` 的关系决定是否越过重复值。

## 运行

```bash
TAG=latest scripts/run-example.sh c L3-017-bsearch-variants
```
