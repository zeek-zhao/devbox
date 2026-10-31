<!-- coverage: pending -->

# L1-007-v-model-expand

## 考点

分别用组件 `v-model` 和 `:modelValue` 加 `@update:modelValue` 渲染同一个子组件。子组件检查 vnode 属性，能看到 `modelValue` 与 `onUpdate:modelValue`。

## 易错点

组件上的 `v-model` 是 `modelValue` prop 与 `update:modelValue` 事件监听器的语法糖。

## 复现

```bash
TAG=local scripts/run-example.sh vue L1-007-v-model-expand
```
