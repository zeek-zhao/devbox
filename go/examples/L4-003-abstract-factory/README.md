# L4-003-abstract-factory

<!-- coverage: pending -->

## 考点

对应 KP-GO-L4-03：一个工厂接口成组创建一族相互配套的产品，切换工厂即切换整套实现。

可观察判据：两个工厂实现成组返回 `Button`/`TextBox` 两个接口，同族产品 `Family()` 相同且跨族不同。

## 为什么这样写

结构位置：`main.go:5-16` 为产品与工厂接口，`main.go:18-34` 为两族实现，`main.go:36-47` 为同族及跨族比较。

`main.go` 的 `Factory` 声明 `CreateButton()` 和 `CreateTextBox()`；`LightFactory`、`DarkFactory` 分别创建各自族的两种产品。
`ShowFamily()` 只使用工厂接口及产品接口，实际调用两个产品的 `Family()`，比较同族并返回族名；`main()` 再比较跨族。
如果暗色工厂混入亮色文本框，第二行会变成 `button=dark textbox=light matched=false`。
如果两个工厂返回同一族，最后一行会变成 `different families: false`，不是直接打印预设结论。

## 怎么跑

TAG=latest bash scripts/run-example.sh go L4-003-abstract-factory
