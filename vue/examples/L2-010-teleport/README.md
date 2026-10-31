<!-- coverage: pending -->

# L2-010-teleport —— 观察 Teleport 的 SSR 输出与目标内容

## 考点

- 将内容 Teleport 到 `#target`，检查 SSR 主 HTML 中的 teleport 标记。
- 从 SSR 上下文的 `teleports` 字段取得目标 HTML。

## 为什么这么写

浏览器中 Teleport 会把节点挂到目标 DOM；SSR 没有 DOM 可移动，主 HTML 保留边界标记，目标内容由 renderer 单独放入上下文。本例同时检查这两部分。

## 易错点

- 不能期待 SSR 返回字符串里直接包含目标节点内容。
- SSR 要传入上下文对象，才能读取 `context.teleports`。

## 运行

```bash
TAG=latest scripts/run-example.sh vue L2-010-teleport
```
