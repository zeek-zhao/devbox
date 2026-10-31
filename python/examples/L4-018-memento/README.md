# L4-018-memento

<!-- coverage: pending -->

## 考点

对应 KP-PY-L4-18：在不破坏封装的前提下保存并恢复对象内部状态。

可观察判据：备忘录对象只读（`__slots__` 或冻结），恢复后字段与保存时一致。

## 为什么这样写

`Memento` 的 `@dataclass(frozen=True)` 行冻结字段，标签使用不可变 tuple。
原发器 `QuerySession.save()` 将内部列表转成 tuple；`restore()` 的 `list(memento.tags)` 行恢复独立列表。
管理者 `History` 只保存和交还快照，不修改原发器内部字段。
`main()` 真实修改原发器、尝试篡改快照并捕获 `FrozenInstanceError`，然后恢复并比较所有字段。
去掉冻结，第三行变成断言失败；去掉恢复赋值，第四行仍是编辑后的状态且第五行是 `False`；
最后一行验证恢复后再次编辑仍不会污染历史。

## 怎么跑

TAG=latest bash scripts/run-example.sh python L4-018-memento
