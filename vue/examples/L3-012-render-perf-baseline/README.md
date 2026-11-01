<!-- coverage: pending -->

# L3-012-render-perf-baseline —— 一千次真实 SSR 的秒级门槛

## 考点

- 同一个组件定义执行一千次 SSR，每次新建应用并传入不同 count。
- 逐次校验 HTML，累计实际渲染次数及输出字节数。
- 单调时钟测总耗时，只输出 <1s 或 >=1s 量级，不输出绝对毫秒数。

## 为什么这么写

选择单一秒级门槛，避免同一次正常运行在 <100ms 与 <1s 之间漂移导致精确比对失败。
计时包含创建应用、await SSR 和结果校验，不含模块加载；没有预热或缓存输出。
超过一秒就输出 >=1s，与 expected.txt 不匹配，不能为了 CI 通过伪造量级。
每次 count 改变可暴露缓存常量 HTML 或空循环，字节总数来自真实结果。

## 易错点

- 不 await renderToString 测到的只是 Promise 创建速度。
- 把毫秒值写入 expected.txt 会随机器负载变化。
- 有浏览器渲染与布局开销的基准不能与本例 SSR 基准直接比较。

## 运行

```bash
TAG=latest scripts/run-example.sh vue L3-012-render-perf-baseline
```
