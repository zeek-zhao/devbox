<!-- coverage: exempt todo 应用没有搜索框、远程查询或高频过滤输入，因此没有需要延迟执行或取消的搜索任务。 -->

# L3-008-debounce-search —— 真实定时器的尾缘防抖

## 考点

- 手写 debounce，五次快速输入只查询一次，使用最后一次参数。
- 真正等待 Node setTimeout 后统计调用次数，并 SSR 查询结果。
- cancel 清除待执行查询，模拟组件销毁时的清理。

## 为什么这么写

同步输入保证五次调用都发生在首个定时器前，5ms 防抖后 await 20ms。
不用 lodash 或假时钟库，也不比较毫秒精度。查询直接更新 ref，
SSR 证明 UI 消费的是执行后的结果，不只是打印输入常量。

## 易错点

- 忘记 clearTimeout 会查询五次。
- 在 debounce 外缓存第一次参数，会错用最早输入。
- 没有 await 就打印查询次数，得到的是尚未执行的零次。

## 运行

```bash
TAG=latest scripts/run-example.sh vue L3-008-debounce-search
```
