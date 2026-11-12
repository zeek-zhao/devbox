# L2-018-worker-pool-wait-n

## 考点
对应 KP-SH-L2-18：用后台任务加 wait -n 组成 worker 池，逐个收割退出状态并汇总成功/失败。

## 易错点
只 wait 最后一个 PID 会漏掉中间任务的失败；池要逐个收割每个 PID 的退出码再判定。

## 延伸
把池接入部署巡检：任务数可配、失败任务带上下文重试一次后再计入失败清单。

## 复现
TAG=latest scripts/run-example.sh shell L2-018-worker-pool-wait-n
