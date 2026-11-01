# L4-002-factory-method


## 考点

对应 KP-GO-L4-02：把「创建哪种具体类型」推迟到子类或工厂实现，调用方只依赖抽象产品。

可观察判据：工厂函数返回接口值，两个实现各自 `Name()` 返回固定字符串；调用方只持有接口，不出现具体类型名。

## 为什么这样写

结构位置：`main.go:5-16` 为产品接口、实现与工厂，`main.go:18-27` 为仅依赖接口的调用方。

`main.go` 的 `NewJSONParser()`、`NewTextParser()` 两个工厂各自构造具体产品，但签名均返回 `Product`。
`PrintProduct()` 只接收 `Product` 并调用 `Name()`；`main()` 的 `[]func() Product` 统一调用工厂，不引用具体结构体。
如果把第二个工厂错误接到第一个实现，第二行 `text parser` 会变成 `json parser`。
如果将工厂返回值改为具体类型，即使文本不变，工厂函数也无法放入该函数切片，编译失败；输出和编译约束共同检验结构。

## 怎么跑

TAG=latest bash scripts/run-example.sh go L4-002-factory-method
