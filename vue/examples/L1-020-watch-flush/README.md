# L1-020-watch-flush

## 考点

同一轮更新里 `sync` 立即执行，`pre` 与 `post` 则在 Vue 更新队列中按序运行。

## 易错点

修改 ref 后立即检查异步 watcher 会漏掉回调；需要等待 `nextTick()`。

## 延伸

`post` watcher 适合依赖已更新视图的后置工作，`sync` 则应谨慎用于少量同步状态。

## 复现

```bash
TAG=local scripts/run-example.sh vue L1-020-watch-flush
```
