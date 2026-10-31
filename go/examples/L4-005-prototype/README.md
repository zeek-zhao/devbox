# L4-005-prototype

<!-- coverage: pending -->

## 考点

对应 KP-GO-L4-05：通过克隆已有实例创建新对象，避免重复执行昂贵构造。

可观察判据：用 `Clone() Shape` 方法返回副本，改副本字段不影响原对象。

## 为什么这样写

结构位置：`main.go:5-17` 为原型接口与深克隆，`main.go:27-36` 为克隆后双向修改和观察。

`main.go` 的 `Shape` 声明 `Clone() Shape`，`Diagram.Clone()` 创建新结构体并用 `append([]string(nil), d.labels...)` 复制切片底层数据，不重新准备原型内容。
`main()` 通过接口克隆、修改副本标签，随后再改原对象标签，打印两个方向的隔离效果；`Labels()` 同样返回切片副本以免泄漏内部状态。
如果 `Clone()` 直接返回原指针，首行会变成 `same instance: true`，原对象首标签也会变成 triangle。
如果仅浅拷贝结构体，指针比较仍会通过，但 `original` 和 `clone after original edit` 两行会改变，因此不能用指针不同冒充深拷贝。

## 怎么跑

TAG=latest bash scripts/run-example.sh go L4-005-prototype
