<!-- coverage: pending -->

# L3-001-proxy-reactivity —— 手写懒代理与 receiver 语义

## 考点

- 不加载 Vue，用 Proxy 和 WeakMap 实现 reactive；同一对象始终得到同一代理。
- 深层对象首次读取时才代理，打印代理数量验证不是提前遍历。
- 修改后读回新值；原型链上的 getter/setter 必须以 receiver 为 this。

## 为什么这么写

这里刻意不 `require('vue')`：调用框架 API 无法验证代理实现。双向 WeakMap
避免重复代理，并在写入时还原原对象。通过继承代理的 child 调用访问器，
能区分 Reflect.get/set 的 receiver 与直接读写 target；只测试普通属性看不出这个区别。
JS 写进用例独立的临时目录，仓库仍恰好三个文件。

## 易错点

- `typeof null` 是 object，递归代理前必须排除 null。
- `target[key]` 会把 getter 的 this 绑定到原对象，child.doubled 就会读到父级值。
- set 不传 receiver 会让 child 的 setter 修改父级 count。

## 运行

```bash
TAG=latest scripts/run-example.sh vue L3-001-proxy-reactivity
```
