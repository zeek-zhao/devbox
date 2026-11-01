# L1-004-watch-vs-watcheffect

## 考点

`watchEffect` 注册时立即运行；默认 `watch` 不立即运行，源变化后才回调。`nextTick()` 后观察本轮调度顺序。

## 易错点

不要把默认 `watch` 和 `watchEffect` 的首次执行时机混为一谈。

## 复现

```bash
TAG=local scripts/run-example.sh vue L1-004-watch-vs-watcheffect
```
