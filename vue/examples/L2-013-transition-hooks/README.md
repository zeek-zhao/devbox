<!-- coverage: pending -->

# L2-013-transition-hooks —— 验证 SSR 不触发 Transition 钩子

## 考点

- 给 `Transition` 注册真实的 `onEnter` 回调。
- 在 SSR 完成后检查回调是否被执行。

## 为什么这么写

浏览器挂载或切换 DOM 时 Transition 可调用进入钩子；SSR 不创建真实 DOM，也不执行过渡，因此输出 `false`。状态由回调修改，而不是硬编码。

## 易错点

- SSR 渲染成功不代表过渡钩子运行过。
- 只检查 HTML 无法证明钩子状态；需要在回调中改变可观察变量。

## 运行

```bash
TAG=latest scripts/run-example.sh vue L2-013-transition-hooks
```
