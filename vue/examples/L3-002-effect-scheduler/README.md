# L3-002-effect-scheduler —— 手写依赖收集与微任务批处理

## 考点

- 不加载 Vue，使用 WeakMap → Map → Set 按对象和属性收集 effect。
- 连续三次同步赋值只排入一个微任务批次，初次执行不计入批次次数。
- effect 重跑时清理旧依赖，关闭分支后再改 count 不触发副作用。

## 为什么这么写

不 `require('vue')`，避免把考点交给框架。Set 按 runner 身份去重，
Promise.resolve().then 延迟刷新，await 刷新 Promise 才检查最终值。
enabled 分支用来证明依赖来自实际读取，而不是所有属性改变都触发回调。
这是普通属性的依赖收集示例，不宣称实现完整 Vue 或深层 reactive。

## 易错点

- 每次 set 创建新的闭包，Set 无法去重。
- 同步调用 runner 会执行三次，且无法观察刷新前的旧值。
- 不清理依赖会让已关闭分支继续响应 count 的变化。

## 运行

```bash
TAG=latest scripts/run-example.sh vue L3-002-effect-scheduler
```
