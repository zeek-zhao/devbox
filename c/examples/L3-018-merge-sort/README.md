<!-- coverage: pending -->

# L3-018-merge-sort —— 通过相等键顺序验证归并排序稳定性

## 考点

- 将排序实现放在独立编译单元 `sort.c` 中。
- 对结构体按 key 排序，并观察相同 key 的原始序号顺序。
- 将内部合并辅助函数声明为 `static`。

## 为什么这么写

`main.c` 只依赖公开排序接口，辅助函数保持文件内链接；按 key 与原始序号输出，稳定性可见。

## 易错点

- 左右元素 key 相等时必须先取左侧元素，保持原始相对顺序。
- 临时数组分配失败时不能继续读写空指针。

## 运行

```bash
TAG=latest scripts/run-example.sh c L3-018-merge-sort
```
