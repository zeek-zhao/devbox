# L4-021-strategy

<!-- coverage: pending -->

## 考点

对应 KP-JV-L4-21：把可互换算法封装成对象，运行时替换而不改调用方。

可观察判据：上下文持有策略接口，切换实现后同一输入输出不同结果。

## 为什么这样写

`src/Main.java` 的 `Sorter` 持有 `SortStrategy`，`sort` 只有
`return strategy.sort(input)`，通过 `strategy(value)` 运行时替换。
`Alphabetical`、`ByLength` 分别封装字母序与长度序算法，长度相同时用字母序
消除歧义，两者都复制输入后排序。上下文没有 `switch` 或实现类型判断。
`main` 对同一个上下文、同一份不可变输入调用相同方法。
如果去掉策略替换赋值，`by length` 行也会输出 `[apple, fig, kiwi, pear]`；
如果拆掉委托而直接返回输入，前两行都将变成原始次序。
最后一行还验证输入没有被算法修改。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh java L4-021-strategy
```
