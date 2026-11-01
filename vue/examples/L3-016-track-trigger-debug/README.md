# L3-016-track-trigger-debug

## 考点

watchEffect 的 `onTrack` 与 `onTrigger` 调试钩子分别报告依赖读取和状态写入。

## 易错点

调试事件是开发诊断信息，不应作为生产业务逻辑或稳定的公开输出格式。

## 延伸

在复杂 computed/watch 链中，记录 target、key 与操作类型有助于定位意外依赖。

## 复现

```bash
TAG=local scripts/run-example.sh vue L3-016-track-trigger-debug
```
