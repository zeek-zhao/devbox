# L4-008-composite


## 考点

对应 KP-GO-L4-08：把叶子与容器统一成同一接口，递归组合后可整体操作。

可观察判据：组合结构体实现与叶子相同的接口，遍历输出固定顺序的文本。

## 为什么这样写

结构位置：`main.go:5-15` 为统一接口与叶子，`main.go:17-28` 为容器与递归，`main.go:30-48` 为混合树和统一遍历。

`main.go` 的 `File` 与 `Directory` 都实现 `Node.Walk()`；目录的 `children []Node` 同时保存文件、嵌套目录和空目录。
`Directory.Walk()` 先生成自身行，再按切片顺序递归调用 `child.Walk(indent+"  ")`；`main()` 只通过根节点接口执行一次整体操作。
如果删除递归调用，嵌套的 `file:main.go` 和 `dir:empty` 两行会消失；如果缩进不累加，这两行的空格会改变。
如果把子节点切片改成具体文件类型，两个目录无法装入切片，编译失败。输出的顺序来自有序切片，不依赖 map 遍历。

## 怎么跑

TAG=latest bash scripts/run-example.sh go L4-008-composite
