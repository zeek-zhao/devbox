<!-- coverage: pending -->

# L1-016-ssr-basic

## 考点

用 `createSSRApp` 创建 Vue 应用，再通过 `renderToString` 异步获得完整 HTML。

## 易错点

SSR 用 `createSSRApp`，不要用面向浏览器挂载的 `createApp`。

## 复现

```bash
TAG=local scripts/run-example.sh vue L1-016-ssr-basic
```
