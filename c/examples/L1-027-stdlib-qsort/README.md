<!-- coverage: exempt 路由表固定且顺序无关，不需要运行期排序。 -->

# L1-027-stdlib-qsort —— 为结构体数组提供安全比较函数

## 考点

- `qsort` 接受元素个数、元素大小和通用比较函数。
- 比较函数从 `const void *` 转回元素类型，并按结构体的第二个字段排序。

## 为什么这么写

排序后同时输出 ID 与分数，能看出结构体元素整体移动且比较依据确实是 `score`。

## 易错点

- 直接用两个整数相减比较可能溢出；返回比较关系的负值、零或正值即可。
- 比较函数收到的元素视图不应修改，使用指向 `const struct item` 的指针。

## 运行

```bash
TAG=latest scripts/run-example.sh c L1-027-stdlib-qsort
```
