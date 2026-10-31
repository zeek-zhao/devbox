<!-- coverage: pending -->

# L1-010-lifecycle-order

## 考点

记录 SSR 下 Options API 与 Composition API 生命周期钩子的实际顺序。该环境只执行 `beforeCreate`、`setup`、`created`；挂载和卸载钩子不会执行。

## 易错点

SSR 不会调用 `onBeforeMount`、`onMounted`、`onBeforeUnmount` 或 `onUnmounted`；不能把浏览器挂载顺序当成 SSR 观察结果。

## SSR 下这条为什么不适用 / 实际观察到什么

服务端渲染只创建组件并生成 HTML，没有真实挂载或卸载过程。因此这里的 `onBeforeMount`、`onMounted` 和 `onBeforeUnmount` 都不触发；实际打点为 `beforeCreate, setup, created`。

## 复现

```bash
TAG=local scripts/run-example.sh vue L1-010-lifecycle-order
```
