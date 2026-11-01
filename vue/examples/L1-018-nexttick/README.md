<!-- coverage: pending -->

# L1-018-nexttick

## 考点

修改 ref 后立即检查 DOM 代理，再 `await nextTick()` 后检查。SSR 环境两次都没有 DOM；`nextTick` 仍可用于等待 Vue 调度微任务。

## 易错点

不要把浏览器中的 DOM 更新队列行为套用到 SSR。`nextTick` 不会在服务端创建 DOM。

## SSR 下这条为什么不适用 / 实际观察到什么

SSR 没有 DOM 代理，也没有浏览器 DOM 更新队列。ref 状态会正常更新，但 DOM 代理前后都不可用；`nextTick` 只保证异步调度顺序。最后由 SSR 渲染当前状态。

## 复现

```bash
TAG=local scripts/run-example.sh vue L1-018-nexttick
```
