# L4-019-observer


## 考点

对应 KP-PY-L4-19：主题状态变化时通知所有已注册观察者，主题不依赖观察者的具体类型。

可观察判据：注册两个回调后触发一次通知产生两行固定输出，注销后只剩一行。

## 为什么这样写

`Subject.register/unregister` 管理回调，`update()` 的版本递增行改变状态，
随后通过 `callback(self._version)` 行通知观察者，不引用具体回调名称。
遍历 tuple 快照，回调期间注销不会跳过本轮后续观察者，本轮注册只在下轮生效。
两行版本 1 输出来自第一次通知；删除注销行，第二次会多出 `cache: version=2`；
删除回调调用行，三行全部消失。

## 怎么跑

TAG=latest bash scripts/run-example.sh python L4-019-observer
