# E-012-retry-backoff

## 现象
三种重试结局：瞬时错误抖两次后第 3 次成功；持续抖动 5 次耗尽后放弃；
永久性错误第 1 次就立即放弃。重试间隔按 2ms/4ms/8ms 指数退避真睡。

## 复现
```bash
TAG=latest bash scripts/run-example.sh cpp E-012-retry-backoff
```

## 期望输出
```text
attempt 1: transient: connection reset
attempt 2: transient: connection reset
attempt 3: ok
attempt 1: transient: connection reset
attempt 2: transient: connection reset
attempt 3: transient: connection reset
attempt 4: transient: connection reset
attempt 5: transient: connection reset
give up: attempts exhausted
dead attempt 1: permanent: bad request
dead: give up immediately
```

## 为什么
重试没有上限就是把瞬时故障放大成雪崩——下游越抖你打得越狠；没有
退避就是在故障窗口里以恒定频率撞墙。指数退避让重试压力逐步衰减，
给对端恢复时间；上限保证最坏情形有确定的结束点。错误先按
transient/permanent 分类：永久性错误重试永远不会成功，立即放弃并把
错误向上报才是对的——「先重试三次再说」的万能兜底通常在掩盖分类缺失。

## 反例
`while (true) { try { call(); break; } catch (...) {} }`——无上限、无
退避、无分类，三样全缺；或者重试整个非幂等操作（下订单重发三次
变三单）；或者 catch 里 sleep 固定 1s 重试 100 次——调用方等到天荒地老。

<!-- coverage: exempt 排障示例（错误处理演练），不落入任何毕业项目代码；豁免理由与错误处理章统一归档于 cpp/docs/排查手册.md（M11-DOC-cpp 卡落盘） -->
