<!-- coverage: exempt todos/about 是轻量静态视图，切换时不持有需要保留的复杂局部状态或昂贵实例，缓存它们没有应用价值。 -->

# L2-012-keep-alive —— 观察 KeepAlive 在 SSR 中直通渲染

## 考点

- 在 `KeepAlive` 插槽中渲染组件，并检查 SSR 最终 HTML。
- 确认服务端渲染组件内容，不输出缓存容器标记。

## 为什么这么写

浏览器中的 KeepAlive 会缓存切换出去的组件实例；SSR 没有跨导航的客户端实例缓存，因而退化为直通渲染。期望输出是子组件本身的 HTML。

## 易错点

- 不能把 SSR 中一次成功渲染误解为组件已被缓存。
- KeepAlive 不会为 SSR 输出额外 DOM 包装层。

## 运行

```bash
TAG=latest scripts/run-example.sh vue L2-012-keep-alive
```
