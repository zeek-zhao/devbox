# E-014-fail-fast

## 现象
坏配置（workers=0）在 `start_batch` 入口即被拒绝：抛出诊断明确的
异常时资源占用为零（cleanup: release 0 items）；好配置正常走完，
退出时释放 2 项。拒绝发生在任何副作用之前。

## 复现
```bash
TAG=latest bash scripts/run-example.sh cpp E-014-fail-fast
```

## 期望输出
```text
fail-fast: config: workers must be positive
cleanup: release 0 items
batch: started with 4 workers
cleanup: release 2 items
```

## 为什么
「带着坏状态继续跑」是故障扩散的标准剧本：错误的数据流进下游、
被持久化、再被别的模块读到——修复成本随时间指数增长。快速失败的
纪律是：不可恢复的错误（配置错、不变式破、依赖缺失）在离错误源
最近的地方立即中止，且中止尽量发生在副作用之前（先校验、后占
资源），失败就是干净的零状态。可恢复的错误（瞬时网络抖动）另走
重试/降级通道——分类是选择 fail fast 还是 retry 的前提。

## 反例
入口发现坏配置却打个日志继续跑，用默认值硬凑——故障被推迟到
更难定位的下游；或者先分配资源再校验参数——失败路径背上回滚
包袱；或者 catch 后 `exit(0)`——退出码撒谎，监控系统全盲。

<!-- coverage: exempt 排障示例（错误处理演练），不落入任何毕业项目代码；豁免理由与错误处理章统一归档于 cpp/docs/排查手册.md（M11-DOC-cpp 卡落盘） -->
