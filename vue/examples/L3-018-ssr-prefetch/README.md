# L3-018-ssr-prefetch

## 考点

SSR 等待 `onServerPrefetch` Promise 完成后再输出 HTML；失败路径将状态改为明确的降级内容。

## 易错点

只在客户端生命周期取数会导致首屏 SSR 仍是 loading；预取错误也不能静默伪装成成功数据。

## 延伸

客户端 hydration 应使用与服务端相同的预取结果或序列化快照，避免首屏内容不一致。

## 复现

```bash
TAG=local scripts/run-example.sh vue L3-018-ssr-prefetch
```
