# L2-020-emits-validation

## 考点

对象形式的 `emits` 声明可校验事件负载；`warnHandler` 捕获无效参数产生的 warning。

## 易错点

事件 validator 返回 false 是开发期警告，不会取消事件，也不会自动转换负载。

## 延伸

组件边界处校验事件 payload，可尽早发现父子组件契约不一致。

## 复现

```bash
TAG=local scripts/run-example.sh vue L2-020-emits-validation
```
