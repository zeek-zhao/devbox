# L4-011-flyweight

<!-- coverage: pending -->

## 考点

对应 KP-GO-L4-11：共享内在状态、外部状态由调用方传入，避免重复创建大量同质对象。

可观察判据：`map` 缓存按 key 复用，相同 key 两次取到同一指针，创建计数固定。

## 为什么这样写

结构位置：`main.go:8-14` 分离内外状态，`main.go:16-43` 为有界缓存与创建计数，`main.go:45-75` 为复用、绘制及容量边界观察。

`main.go` 的 `Glyph` 只保存内在符号，`Draw(x, y)` 从调用方接收外在坐标；同一个 A 指针在两个位置绘制，不把坐标存入共享对象。
`GlyphFactory.Get()` 先查 `cache map[string]*Glyph`，仅未命中且未满时创建并递增计数。
`main()` 实际两次取 A、一次取 B 后比较指针和计数；如果不复用，`same key pointer` 会变成 false，或者第二次 A 就耗尽容量导致非零退出。
工厂有显式容量和参数校验，满时新 key 返回错误；再次取已有 A 仍成功。删除容量检查会让 `new key at capacity` 变成 `<nil>`，最后计数变成 3。
示例串行使用工厂，不承诺并发安全；非预期错误 panic，容量耗尽错误则明确打印。

## 怎么跑

TAG=latest bash scripts/run-example.sh go L4-011-flyweight
