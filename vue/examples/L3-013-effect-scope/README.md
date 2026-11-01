# L3-013-effect-scope

## 考点

`effectScope` 收集作用域中创建的 watchEffect；调用 `stop()` 后一并停止响应。

## 易错点

只停止某个 watcher 会遗漏同作用域其他副作用；作用域需在组件或请求生命周期结束时显式清理。

## 延伸

请求级 store 可将其 watcher 放入 effect scope，并在 SSR 请求完成后停止作用域。

## 复现

```bash
TAG=local scripts/run-example.sh vue L3-013-effect-scope
```
