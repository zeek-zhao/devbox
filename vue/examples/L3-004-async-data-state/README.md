<!-- coverage: pending -->

# L3-004-async-data-state —— Promise 驱动加载、错误与空态

## 考点

- reactive 状态由请求 Promise 的 pending/rejected/fulfilled 驱动。
- 同一组件对加载、错误、空结果各执行一次 SSR。
- 重试清除旧错误；成功的空数组不是请求失败。

## 为什么这么写

用可控的拒绝 Promise 保持加载阶段，避免快速请求在 SSR 前已经落定。
加载态有意在 pending 时渲染；错误和空态必须 await load 后才渲染。
请求错误由明确的 error UI 展示，不吞掉错误并返回成功态。
不需要浏览器或额外 Suspense 依赖。

## 易错点

- 忘记 await load，错误/空态的 SSR 仍然打印 Loading。
- 重试未清除 error，会把旧错误带进新请求。
- 拒绝 Promise 前未绑定错误处理会造成 unhandled rejection。

## 运行

```bash
TAG=latest scripts/run-example.sh vue L3-004-async-data-state
```
