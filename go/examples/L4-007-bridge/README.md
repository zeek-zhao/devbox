# L4-007-bridge

<!-- coverage: pending -->

## 考点

对应 KP-GO-L4-07：把抽象与实现分离成两个独立继承体系，二者可独立扩展。

可观察判据：抽象侧结构体持有实现接口，两种组合输出固定标签。

## 为什么这样写

结构位置：`main.go:5-13` 为实现维度，`main.go:15-33` 为持有实现接口的抽象维度，`main.go:35-45` 为四种组合调用。

Go 用接口与组合而非继承表达两个维度。`main.go` 的 `Notice`、`Alert` 实现抽象侧 `Message`，各自持有 `Renderer` 接口。
`PlainRenderer`、`HTMLRenderer` 是实现侧两种格式；两个 `Display()` 方法把各自标签交给 `renderer.Render()`。
`main()` 固定顺序运行两种消息与两种渲染器的四种交叉组合，证明不是把一个维度写死在另一个维度内。
如果 `Notice.Display()` 绕过桥接直接拼纯文本，第二行 `<p>notice:go</p>` 会改变；若字段改为具体渲染器类型，另一格式的组合会编译失败。

## 怎么跑

TAG=latest bash scripts/run-example.sh go L4-007-bridge
