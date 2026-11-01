<!-- coverage: exempt 页面没有需要隔离的故障子组件；全局 errorHandler 记录未处理错误，并不使用 onErrorCaptured 的组件级恢复边界。 -->

# L2-008-error-captured —— 用 onErrorCaptured 捕获子组件错误

## 考点

- 子组件在 `setup` 中抛错，由父组件的 `onErrorCaptured` 接收。
- 在 SSR 中等待 `renderToString` Promise，并把未捕获异常作为失败处理。

## 为什么这么写

捕获钩子记录错误消息并返回 `false`，阻止错误继续向上冒泡；单独的 Promise `catch` 保留 SSR 错误的非零失败路径。

## 易错点

- SSR 的渲染错误可能通过 `renderToString` 返回的 Promise 抛出，不能只包同步 `try/catch`。
- 捕获钩子不返回 `false` 时，错误可能继续传播到更高层。

## 运行

```bash
TAG=latest scripts/run-example.sh vue L2-008-error-captured
```
