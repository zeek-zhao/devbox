# L4-004-builder


## 考点

对应 KP-GO-L4-04：用链式步骤逐步构造复杂对象，最终 `build()` 一次性产出结果。

可观察判据：链式方法返回建造者指针，`Build()` 产出结构体；必填项缺失时返回非 nil error。

## 为什么这样写

结构位置：`main.go:18-26` 为链式步骤，`main.go:28-36` 为校验与值对象构建，`main.go:38-55` 为两次构建、修改和失败路径。

`main.go` 的 `WithQuery()`、`WithLimit()` 修改建造者私有字段并 `return b`，支持链式步骤；`Build()` 校验必填查询和正数上限，返回新的 `Request` 值。
`main()` 两次构建，中间改建造者上限，之后改第二份结果查询；打印两份字段并计算 `independent`。
若结果与建造者共享可变对象，第一行会受到第二次修改影响；如果删除必填校验，`missing query: query is required` 会变成 `missing query: <nil>`。
成功路径的非预期错误直接 panic，以非零退出显式暴露；缺查询是刻意执行的失败路径，不隐藏错误。

## 怎么跑

TAG=latest bash scripts/run-example.sh go L4-004-builder
