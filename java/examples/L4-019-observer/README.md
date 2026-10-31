# L4-019-observer

<!-- coverage: pending -->

## 考点

对应 KP-JV-L4-19：主题状态变化时通知所有已注册观察者，主题不依赖观察者的具体类型。

可观察判据：主题维护监听器列表，通知按注册顺序输出，移除后不再回调。

## 为什么这样写

`src/Main.java` 的主题 `Index` 保存 `List<Observer>`，`update` 先递增
真实版本字段，再逐个调用 `observer.updated(version)`，不判断具体实现类型。
通知时复制注册列表，保持顺序并避免回调修改列表干扰当前遍历。
`Cache`、`Audit` 各自实现回调；`main` 注册后更新，移除缓存后再更新，
最后移除审计再次更新，此时不产生任何回调输出。
如果去掉通知循环，三行全部消失；如果去掉 `remove` 的移除动作，
第二次会多出 `cache invalidated: 2`，第三次也会多出回调。
显式注销也解除主题对监听器的强引用。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh java L4-019-observer
```
