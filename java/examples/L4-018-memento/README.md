# L4-018-memento

<!-- coverage: pending -->

## 考点

对应 KP-JV-L4-18：在不破坏封装的前提下保存并恢复对象内部状态。

可观察判据：备忘录为不可变对象，`restore` 后字段回到保存时值。

## 为什么这样写

`src/Main.java` 的原发器 `Session` 内定义私有 `Memento` record，
构造器中的 `filters = List.copyOf(filters)` 使快照既不可写也不共享可变集合。
`restore` 恢复字符串并通过 `clear`、`addAll` 把快照内容复制回私有列表。
`main` 充当保管者，只保存与交还备忘录，输出通过原发器 `describe` 读取。
保存后同时改查询和过滤器，恢复后再次改过滤器并使用同一快照恢复。
如果去掉查询赋值，`restored: java [open]` 的查询仍为 `patterns`；
如果共享列表，恢复时的 `clear` 会清空快照，恢复两行将不再是 `[open]`。
因此两轮恢复同时检查正向与反向的集合隔离。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh java L4-018-memento
```
