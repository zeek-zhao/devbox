coverage: exempt 项目页面没有 Teleport 目标或按需加载模块；引入传送层和模块收集不会服务现有 Todo 页面结构。

# L2-019-ssr-context

## 考点

`renderToString` 将 Teleport 目标 HTML 和 SSR 模块 ID 分别收集到传入 context 的 `teleports` 与 `modules`。

## 易错点

Teleport 内容不在主 HTML 字符串中；模块集合只有 SSR render 代码显式记录时才会包含 ID。

## 延伸

服务端可根据模块集合生成预加载资源，根据 teleports 内容将弹层插入文档中的目标节点。

## 复现

```bash
TAG=local scripts/run-example.sh vue L2-019-ssr-context
```
