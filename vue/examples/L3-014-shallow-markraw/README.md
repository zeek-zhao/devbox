# L3-014-shallow-markraw

## 考点

shallow ref/reactive 只追踪根层替换；`markRaw` 让指定对象即使放入 reactive 容器也不被代理。

## 易错点

浅层 API 下修改嵌套属性不会触发依赖；需要替换根值，或明确选择深响应式 API。

## 延伸

浅层状态适合大型不可变数据快照；markRaw 适合不应代理的第三方实例。

## 复现

```bash
TAG=local scripts/run-example.sh vue L3-014-shallow-markraw
```
