# L4-018-memento

<!-- coverage: exempt 网关无编辑会话或回滚操作；9 字节 checkpoint 只序列化 ID 与总词数，不能恢复 worker、令牌桶或词频状态，不是可恢复的对象备忘录 -->

## 考点

对应 KP-GO-L4-18：在不破坏封装的前提下保存并恢复对象内部状态。

可观察判据：原发器提供 `Save()`/`Restore()`，恢复后字段等于保存时的值。

## 为什么这样写

`main.go` 第 5–21 行将备忘录字段设为非导出，原发器在保存和恢复时都复制
切片底层数据。第 33–38 行的管理者只保存并交回备忘录，不读取或修改其字段。
第 44–51 行先保存，再修改字符串和切片元素、恢复、再次修改并恢复同一快照。
若保存时不复制切片，`restored: text=draft tags=[original]` 的标签会变为
`[changed]`；若恢复时不复制切片，第二次恢复的标签会变为 `[changed-again]`。
因此两次恢复同时验证封装的恢复入口和快照与当前状态互不污染。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh go L4-018-memento
```
