# L4-006-adapter


## 考点

对应 KP-GO-L4-06：把不兼容的既有接口包装成调用方期望的接口，且不修改被适配方。

可观察判据：结构体嵌入旧类型并实现目标接口，接口调用转发到旧方法，输出一致。

## 为什么这样写

结构位置：`main.go:8-15` 为旧类型，`main.go:17-29` 为目标接口与嵌入式适配器，`main.go:31-40` 为两条调用路径比较。

`main.go` 的旧类型只提供 `FindRecord()`，不知道新 `Lookup` 接口；`LookupAdapter` 嵌入 `*LegacyLookup`，新方法 `Lookup()` 转发至旧方法。
`var _ Lookup = LookupAdapter{}` 做编译期接口检查；`main()` 分别直接调用旧方法和通过目标接口调用，比较实际结果。
如果适配器不转发而伪造同样字符串，`legacy calls: 2` 会变成 1；若转发时改变参数，`adapted` 和 `same result` 会改变。
如果删掉或改错适配器方法名，接口检查及赋值都会编译失败，不需改动旧类型来凑接口。

## 怎么跑

TAG=latest bash scripts/run-example.sh go L4-006-adapter
