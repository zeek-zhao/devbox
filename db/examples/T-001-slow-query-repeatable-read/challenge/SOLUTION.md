# SOLUTION · T-001-slow-query-repeatable-read（faded 挑战档答案）

> 仅供自查，**不进 CI 断言**（docs/72 §4.3）。先自己写完判读再回来对。
> 以下输出均为 2026-11-06 devbox-db compose 栈真跑（mysql 8.4.13）。

## 1. 先趟环境坑，再谈查询

`wait-ready.sh` 空转超时（`open .../docker-compose.yml: no such file or directory`）
是 `$HOME/.devbox-db-compose` 指向旧 worktree 的覆盖文件在作祟——容器其实已 healthy
（S-06 纪律：先查探测本身，再查服务）。修覆盖文件或直接 `docker ps` 判健康。

## 2. 「全表扫」：计划与实况两证 + 修复三证

```text
EXPLAIN-SCAN: type=ALL key=NULL rows=19737 (query val=19999 -> 19999)
HANDLER-SCAN: read_rnd_next=20001
```

EXPLAIN 的 `type=ALL / key=NULL` 坐实「计划无索引」；`FLUSH STATUS; <查询>;
SHOW SESSION STATUS LIKE 'Handler_read%';` 的 `Handler_read_rnd_next=20001` 坐实
「引擎真的逐行读了两万次」。rows 三次实测 19737 / 19533 / 20282（±4%，InnoDB 统计
采样漂移）——**rows 是估计值，断言只锚量级（>=10000）与 type/key，逐字比对必然假失败**。

修复 = `CREATE INDEX idx_val ON big(val)`，验证三证：

```text
EXPLAIN-IDX: type=ref key=idx_val rows=1
HANDLER-IDX: read_rnd_next=0
RESULT: 19999
```

计划（type/key/rows）+ 实况（Handler 归零）+ 结果（不变）——「变快了」的体感不算证据。

## 3. 「提交了读不到」：不是 bug，是 RR 快照语义

双会话时序（B 在 A 的 SLEEP 窗口内 `INSERT ... COMMIT`）：

```text
first_read=1
second_read=1
fresh_read=2
```

A 的**首次读**建立一致性视图，此后本事务普通读只看快照——B 已提交的插入对 A 不可见；
新连接读到 2（H1 否决「B 没提交成功」：fresh_read=2 证明数据全局可见）。mysql 8.4
已移除查询缓存，机制是 MVCC 版本链（H2 否决「缓存捣乱」）。工单出口：查
**连接维度**——该连接是否长期 open transaction（`INNODB_TRX`），业务侧缩短事务或
显式降级到 READ COMMITTED。

predict–observe–explain：预测「B COMMIT 了 A 就能读到 2」→ 观察 second_read=1、
fresh_read=2 → 解释：可见性边界在「快照建立时刻」，不在「读取时刻」。

## 4. 被否决的假设（详见上层 WALKTHROUGH §5.2）

H1 B 没提交成功 → fresh_read=2 否决；H2 查询缓存捣乱 → 8.4 已删该特性，机制是 MVCC，
否决；H3 rows 可钉精确值 → ±4% 漂移实测，否决；H4 2 万行造不出「慢」→ 判据钉扫描量
证据链，壁钟只是果，修正。
