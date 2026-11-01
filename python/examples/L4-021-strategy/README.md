# L4-021-strategy


## 考点

对应 KP-PY-L4-21：把可互换算法封装成对象，运行时替换而不改调用方。

可观察判据：上下文注入策略对象，切换后同一输入输出不同固定结果。

## 为什么这样写

`AlphabeticalSort/LengthSort` 实现同一抽象 `sort()` 接口；
`WordSorter.sort()` 的转发行不关心算法，`set_strategy()` 的赋值行允许运行期替换。
`main()` 对同一个上下文、同一份输入分别运行两次，不重建上下文。
删除策略替换，第二行会与第一行的序列相同。两个策略均返回新列表，
第三行确认输入不变，按长度排序还保持同长度词 `pear/kiwi` 的原顺序。

## 怎么跑

TAG=latest bash scripts/run-example.sh python L4-021-strategy
