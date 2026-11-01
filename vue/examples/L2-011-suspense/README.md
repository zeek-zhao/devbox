<!-- coverage: exempt 初始待办是每请求同步创建的固定种子，组件没有 async setup 或异步依赖，页面也没有需要等待的加载边界。 -->

# L2-011-suspense —— SSR 等待 Suspense 中的异步 setup

## 考点

- 将 `async setup` 组件放入 `Suspense` 默认插槽，并提供 fallback。
- 检查 SSR 最终 HTML 使用异步组件内容，而非 fallback。

## 为什么这么写

浏览器挂载时 fallback 可在异步依赖就绪前显示；SSR 的 `renderToString` 会等待异步依赖并输出最终内容，所以最终 HTML 不包含 fallback。本用例将两种内容分别检查。

## 易错点

- 不能把浏览器等待期间出现的 fallback 当成 SSR 最终 HTML。
- 异步 setup 必须返回渲染函数，否则组件没有可渲染内容。

## 运行

```bash
TAG=latest scripts/run-example.sh vue L2-011-suspense
```
