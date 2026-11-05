# T-001-slow-query-repeatable-read · faded 挑战档

> 规则（docs/72 §4.3）：这里只给触发症状与可用工具清单，不给判读。
> 请先自己按 WALKTHROUGH 的 §4.1 结构（触发症状 / 前 60 秒三条只读检查 / 互斥决策树 /
> 逐行判读 / 改动后验证）写一遍，再对照 [SOLUTION.md](SOLUTION.md)。

## 触发症状

同事报障两件事。其一：报表接口 `SELECT ... WHERE biz_no = ?` 结果从来没错过，但
DBA 说它在「全表扫」，表才 2 万行、现在不慢，可扫描量是 2 万——「以后呢？」。
其二：运营改数据后去页面核对，页面上还是旧值；DBA 说数据早就 COMMIT 了，
让你查「是不是你们应用的事务没提交」。你在 devbox-db compose 栈里拿到缩小版现场：

```bash
bash db/scripts/up.sh && bash db/scripts/wait-ready.sh   # 若 wait-ready 空转超时，先查 $HOME/.devbox-db-compose
docker exec devbox-db-mysql-1 env MYSQL_PWD=devbox mysql -uroot -N -B db_lab_t001 \
  -e "EXPLAIN SELECT val FROM big WHERE val = 19999;"
bash db/labs/T-001-slow-query-repeatable-read/repro.sh; echo "rc=$?"
```

结果永远正确、COMMIT 也成功了——但「扫描量 20001」与「second_read 停在旧值」都是
事实，review 时谁也指不出哪一行 SQL 有问题。

## 你的任务

1. 先排除「栈没起来 / 探测本身坏了」（wait-ready 有一个现成的环境坑，先趟过去）；
2. 用两种以上手段把「全表扫」从计划钉到实况；回答：为什么 EXPLAIN 的 rows 不能
   逐字断言？建索引后拿什么证明修好了（至少三证）？
3. 双会话复现快照读时序，回答：B 提交成功后 A 为什么读不到？这是 bug 吗？
   把「工单该往哪个方向查」写清楚。

## 可用工具清单

- devbox-db compose 栈（mysql:8.4；口令 devbox 为教学固定值，ROADMAP KI-06 已声明）
- `EXPLAIN`（执行计划）、`FLUSH STATUS + SHOW SESSION STATUS LIKE 'Handler_read%'`
  （引擎层实况）、`SELECT @@transaction_isolation`（语义前提）
- 双会话时序：`docker exec -i ... mysql`（A 连接内连续执行）+ 后台进程 + 另一 exec 做 B
- 同目录 `repro.sh` / `run.sh` / `assert.sh` 可作对照（先别看 WALKTHROUGH）

## 提交判据

`bash assert.sh` 输出 ASSERT-PASS；你的判读文档里至少有 1 个 predict–observe–explain
点与 2 条被否决的假设；验证完执行 `bash db/scripts/down.sh` 收尾。
