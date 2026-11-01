# L3-015-custom-ref

## 考点

`customRef` 把依赖收集交给 `track`，并在定时器确认最终值后调用 `trigger`。

## 易错点

忘记 `track()` 会让读取者不订阅，忘记 `trigger()` 则值变了也不会刷新依赖。

## 延伸

可将相同模式用于输入防抖、缓存失效或外部状态桥接，同时在实际组件卸载时清理定时器。

## 复现

```bash
TAG=local scripts/run-example.sh vue L3-015-custom-ref
```
