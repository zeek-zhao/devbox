<!-- coverage: pending -->

# L3-003-hydration-mismatch —— 确定性模拟水合输入不一致

## 考点

- 同一个组件分别以 client:false 和 client:true 渲染。
- 实际比较两份 SSR HTML，打印零基首个差异位置及字符。
- 首次客户端内容必须与服务端一致，否则真实水合会遇到不匹配。

## 为什么这么写

固定的 server-fixed/client-fixed 模拟时间或随机值的两端差异，避免不稳定期望。
没有浏览器，所以客户端首次渲染也用 renderToString 表示预期 HTML；
本例验证不一致的成因，不宣称执行 DOM 水合或捕获浏览器水合警告。

## 易错点

- 使用 Date.now 或 Math.random 会让差异位置与字符漂移。
- 只打印两段常量而不渲染组件，无法证明输入如何影响视图。
- 差异下标从 0 开始，HTML 标签也占字符位置。

## 运行

```bash
TAG=latest scripts/run-example.sh vue L3-003-hydration-mismatch
```
