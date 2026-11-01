# L1-005-props-one-way

## 考点

父组件通过 prop 向子组件传入 `message`，子组件只读取该值并由 SSR 渲染出来。

## 易错点

Props 是单向数据流；子组件不应直接修改父组件传入的 prop。

## 复现

```bash
TAG=local scripts/run-example.sh vue L1-005-props-one-way
```
