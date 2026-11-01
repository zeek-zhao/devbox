# L1-006-emits-declare

## 考点

子组件声明 `add` 事件并通过 `emit('add', n)` 发送负载，父组件用 `onAdd` 接收。

## 易错点

组件应声明自己发出的事件；未声明的事件监听器会按 `$attrs` 规则处理。

## 复现

```bash
TAG=local scripts/run-example.sh vue L1-006-emits-declare
```
