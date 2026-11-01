<!-- coverage: pending -->

# L1-008-slots

## 考点

父组件向子组件传入默认插槽、具名 `header` 插槽和作用域 `item` 插槽，再由 SSR 渲染三者。

## 易错点

作用域插槽收到的是子组件调用插槽时传出的对象；父组件从该对象中解构 `name`。

## 复现

```bash
TAG=local scripts/run-example.sh vue L1-008-slots
```
