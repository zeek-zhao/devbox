---
title: WALKTHROUGH · T-001-slow-query-repeatable-read（MySQL 慢查询定位与可重复读快照读）
track: db
lab: T-001-slow-query-repeatable-read
难度: P2          # P0–P5 刻度：需跨 EXPLAIN 执行计划 / Handler 计数器 / 双会话事务时序三类手段交叉验证
status: draft
owner: zeek.zhao <zeek.zhao@foxmail.com>
last_verified: 2026-11-06
素材: 类型②实验（复现命令见 §1）+ 素材 S-07（CI 全绿 ≠ 教学质量达标 → 查询正确 ≠ 走对路径）+ 素材 S-06（环境先行）
verified_env: devbox-db compose 栈（mysql:8.4 实测 8.4.13，项目名 devbox-db，docker on linux/amd64）
---

# WALKTHROUGH · T-001-slow-query-repeatable-read

> 依据 [docs/72 排障演练规范](../../../../docs/72-排障演练规范.md) §4 编写。所有输出均为
> 2026-11-06 在 devbox-db compose 栈内真跑所得。与样板 go/examples/T-001-goroutine-leak 的
> 差异点：db 轨道的 lab 脚本跑在**宿主**（有 docker CLI）上、通过 `docker exec` 进入
> mysql 容器执行，而不是进开发容器——「演练环境 = compose 栈本身」。三种检测手段：
> ① EXPLAIN 执行计划（计划）；② `SHOW SESSION STATUS` Handler 计数器（实况）；
> ③ 双会话事务时序（语义现场）。另有一个 db 轨道特有纪律：**用完必须
> `bash db/scripts/down.sh` 收尾**，期间不跑其他 db 任务（compose 项目名固定
> devbox-db）。

## 1. 触发症状

**症状一：查询结果正确，但越来越慢——执行计划里没有索引。** 2 万行的等值查询
`SELECT val FROM big WHERE val = 19999`，值能查对，但计划是全表扫描：

```bash
docker exec devbox-db-mysql-1 env MYSQL_PWD=devbox mysql -uroot -N -B db_lab_t001 \
  -e "EXPLAIN SELECT val FROM big WHERE val = 19999;"
```

真实输出（类型②实验，2026-11-06）：

```text
1	SIMPLE	big	NULL	ALL	NULL	NULL	NULL	NULL	19737	10.00	Using where
```

type=ALL、possible_keys/key 全为 NULL——优化器手里没有任何可用索引，只能逐行扫。
真实事故的形态：表从几千行长到几十万行，这条查询从 10ms 涨到 8s；功能测试全绿
（结果永远是对的，来源：S-07），只有线上延迟曲线在报警。

**症状二：「数据明明提交了，为什么读不到」——事务里的第二次读停在旧快照。**
会话 A 开事务读 `snap` 表（first_read=1），随后 `DO SLEEP(5)` 模拟业务耗时；
期间会话 B `INSERT ... COMMIT` 成功；A 的第二次读仍然是 1，而 A 之外的新连接读到 2：

```text
first_read=1
second_read=1
fresh_read=2
```

这不是 bug，是 mysql 8.4 默认隔离级别 REPEATABLE-READ 的语义（§4.5）——但它是
「重复读看不到自己刚提交的数据」类工单的头号来源。

## 2. 前 60 秒三条只读检查（成本从低到高，均不改任何状态）

| # | 命令 | 健康时看到 | 异常时看到 |
|---|---|---|---|
| 1 | `docker ps --format '{{.Names}}' \| grep devbox-db` | `devbox-db-mysql-1 ... (healthy)` | 容器不在 → 先 `bash db/scripts/up.sh`；连不上是环境问题，不是 SQL 问题（素材 S-06） |
| 2 | `docker exec devbox-db-mysql-1 env MYSQL_PWD=devbox mysql -uroot -N -B -e "SELECT @@transaction_isolation;"` | `REPEATABLE-READ` | 其他值 → 快照读判据要按实际级别重新解读，先记录再继续 |
| 3 | 对慢查询本体跑 `EXPLAIN ...`（只读，不改任何数据） | `type=ref` 且 key 有值 | `type=ALL` 且 key=NULL → 扫描路径坐实，进 §3 决策树 |

三条都只读：不建索引、不改数据、不重启容器。

## 3. 互斥决策树（每叉二选一，无死分支、无循环）

```text
Q0 容器 devbox-db-mysql-1 在跑且 mysql 可达吗？
├─ 否 → 环境：bash db/scripts/up.sh && bash db/scripts/wait-ready.sh；
│     wait-ready 超时先看 \$HOME/.devbox-db-compose 是否指向旧 worktree（§4.0）；
│     连续两次起不来 → 停，交维护者
└─ 是 → Q1 EXPLAIN 的 type 列是什么？
    ├─ ALL（key=NULL）→ Q1' WHERE 列上建过索引吗？
    │   ├─ 没建 → 全表扫坐实 → 看 Handler_read_rnd_next 佐证实况（§4.3）→ §6 建索引验证
    │   └─ 建了却仍 ALL → ① WHERE 里对该列做了函数/隐式转换（索引失效）；
    │         ② 统计信息失真（ANALYZE TABLE 后复查）；③ 数据量太小优化器故意全扫
    │         → 与本 lab 现场不同，登记 UNVERIFIED 交维护者
    ├─ index/ref/range → 计划有索引：慢的原因在别处（锁等待？返回行数大？）
    │     → 与本 lab 现场不同，停，另立现场
    └─ 值查得对但「读不到已提交的新数据」？→ Q2 走快照读分支：
        ├─ second_read 与 first_read 相同、新连接能看到新值
        │     → REPEATABLE-READ 语义坐实（§4.5）→ 排障方向是「这个连接在旧事务里待了多久」
        └─ second_read 就变了 → 隔离级别不是 RR（对照 §2 检查 2 的记录）或 B 还没提交
              → 按实际级别重判；判据歧义 → 停，交维护者
```

## 4. 逐行判读（真实输出，2026-11-06 devbox-db compose 栈真跑）

### 4.0 环境先行：compose 栈、容器名与一个现成的坑

lab 通过 `docker exec devbox-db-mysql-1 env MYSQL_PWD=devbox mysql -uroot` 进入 mysql
容器执行（口令 devbox 是 compose 真本、教学固定值，ROADMAP KI-06 已声明）。栈由
`bash db/scripts/up.sh && bash db/scripts/wait-ready.sh` 起出，compose 项目名固定
`devbox-db`。已知环境坑：`db/scripts/wait-ready.sh` 会读 `$HOME/.devbox-db-compose`
覆盖 compose 文件路径——若该文件指向已被清理的旧 worktree，wait-ready 会以
`open .../docker-compose.yml: no such file or directory` 空转超时（2026-11-06 在
执行机上实测复现）；此时容器其实已经 healthy，先 `docker ps` 直接判健康，再修
覆盖文件。教学点（素材 S-06）：**「就绪探测失败」先查探测本身，再查服务**。

造数用递归 CTE 一次插入 20000 行（`SET SESSION cte_max_recursion_depth=1000000`
解开默认 1000 层递归上限），所有表放在一次性库 `db_lab_t001`，脚本开头
`DROP DATABASE IF EXISTS` 保证可重复运行；`down.sh`（带 -v）负责最终清场。

### 4.1 EXPLAIN：计划层面坐实「全表扫」

```text
1	SIMPLE	big	NULL	ALL	NULL	NULL	NULL	NULL	19737	10.00	Using where
```

- 第 5 列 `type=ALL`：访问类型是全表扫描（最差档）；第 6/7 列 `possible_keys/key`
  双 NULL：优化器手上没有任何可用索引——「没建」与「建了没用」在这一步先分开；
- 第 10 列 `rows=19737`：预计扫描行数。注意它**不是精确值**——同一份数据三次实测
  19737 / 19533 / 20282（±4%），InnoDB 统计采样的必然漂移；assert.sh 只锚
  `>=10000` 的量级，不逐字比对，否则就是「假失败制造机」（docs/72 §2）；
- 第 12 列 `Using where`：过滤在 server 层完成——存储引擎把 2 万行全部交上来再筛，
  这正是慢的来源。

### 4.2 Handler 计数器：从「计划」到「实况」

```text
HANDLER-SCAN: read_key=1 read_rnd_next=20001
```

`FLUSH STATUS; <查询>; SHOW SESSION STATUS LIKE 'Handler_read%';` 三连给出**刚才这一条**
查询的引擎层实况：`Handler_read_rnd_next=20001` = 逐行读了 20001 次（20000 行 +
1 次终结探测）。EXPLAIN 是优化器的打算，Handler 是引擎的账——两者互证才坐实
「慢在扫描量」，而不是锁等待或网络。加索引后同口径复测 `read_rnd_next=0`
（改走 `Handler_read_key=1` + `Handler_read_next=1`），一行都不多读。

### 4.3 修复对照 A：CREATE INDEX（计划 + 计数 + 结果三证）

```text
EXPLAIN-IDX: type=ref key=idx_val rows=1
HANDLER-IDX: read_rnd_next=0
RESULT: 19999
```

唯一改动是 `CREATE INDEX idx_val ON big(val)`：type=ALL → ref、key=NULL → idx_val、
rows 万级 → 1、Handler 归零，且查询结果仍是 19999。修复验证凭三证，不凭「变快了」
的体感——20000 行量级下全扫也只要几十毫秒，体感不可靠；量级涨上去差距才是指数级的
（O(n) vs O(log n)，本 lab 用 EXPLAIN/Handler 把「未来的慢」提前钉出来）。

### 4.4 快照读时序（双会话）

会话 A（一个连接内连续执行，`docker exec -i` 喂同一份 SQL 脚本）：

```text
START TRANSACTION WITH CONSISTENT SNAPSHOT;
first_read=1        ← 首读，事务在此刻定下一致性视图
DO SLEEP(5);        ← 模拟业务耗时（DO 不产生结果集，不污染输出）
second_read=1       ← B 已插入并提交，A 仍读到旧值
COMMIT;
```

会话 B 在 A 的 SLEEP 窗口内（脚本 sleep 2 后执行）：
`START TRANSACTION; INSERT INTO snap VALUES (2, 2); COMMIT;`——**提交成功**。

新连接（第三个独立连接）：`fresh_read=2`。

- `second_read=1` 与 `fresh_read=2` 并存就是 REPEATABLE-READ 的定义：事务内所有
  一致性非锁定读都以**第一次读**建立的快照为准，B 的已提交修改对本事务不可见；
- 时序裕度：A 睡 5s、B 在 t≈2s 提交，两端各留 ≥2s 余量，人工跑与 CI 跑都稳；
- 排障出口：工单「提交了读不到」的判定动作是把 **连接维度** 拉出来看——该连接是否
  长期处于 open transaction（`SELECT * FROM information_schema.INNODB_TRX;`），
  而不是去查「数据到底插没插进去」。

### 4.5 隔离级别是默认行为，不是配置产物

`SELECT @@transaction_isolation` → `REPEATABLE-READ`（mysql 8.4 默认）。快照读
现场不需要任何特殊配置就会发生——这正是它成为高频排障困惑的原因：**语义级「异常」
不报警**（素材 S-07 的语义版：结果自洽 ≠ 语义如你所想）。

## 5. 认知学徒双层（docs/72 §4.2 拍板项）

### 5.1 predict–observe–explain（POE 点）

先书面写下你的预测再跑：

> **预测**：A 会话开事务读 snap 得 1；B 在 A 的事务还没结束时插入 (2,2) 并 COMMIT；
> A 在同一事务里再读一次，读到几？A 提交后新开连接读，读到几？
> （多数人预测：A 第二次读 = 2——「B 都 COMMIT 了，当然读得到」。）

**观察**（真实输出）：`first_read=1`、`second_read=1`、`fresh_read=2`。

**explain 落差**：RR 级别的快照在读**第一次** SELECT 时就定死了视图，此后本事务的
普通读只看快照、不看「之后提交了什么」。COMMIT 的可见性边界是「快照建立时刻」，
不是「读取时刻」。深一层：这与「隔离级别会不会太严」无关——先能预测自己数据库的
默认行为，再谈要不要改。

### 5.2 被否决的假设（≥2 条，含排除过程）

| # | 假设 | 若为真应看到 | 实际看到 | 结论 |
|---|---|---|---|---|
| H1 | B 的 INSERT 没提交成功，所以 A 读不到 | B 会话报错/COMMIT 失败；fresh_read 也是 1 | B 静默成功，fresh_read=2（新连接立刻可见） | 排除：数据已提交且全局可见，只有 A 的事务视图停在旧快照——语义而非故障 |
| H2 | A 第二次读是「缓存」——MySQL 查询缓存在捣乱 | 关掉查询缓存后 second_read 变 2 | mysql 8.4 已移除查询缓存（8.0 起删特性），且 InnoDB 一致性读走 MVCC 版本链，与缓存无关 | 排除：机制是 MVCC 快照，不是缓存；假设本身就建立在已删除的特性上 |
| H3 | EXPLAIN rows=19737 是精确值，断言可以钉 20000 | 每次跑 rows 恒等于 20000 | 三次实测 19737 / 19533 / 20282，±4% 漂移 | 修正：rows 是统计估计，断言锚量级（>=10000）+ type/key，逐字比对必然假失败（docs/72 §2） |
| H4 | 20000 行太小，全扫也不慢，这个 lab 造不出「慢查询」 | 无法从现场读出性能信号 | EXPLAIN type=ALL + Handler 20001 把「扫描量」这个**因**钉死；壁钟时间只是「果」且在本量级不可靠 | 修正：定位慢查询靠扫描量证据链，不靠壁钟；行数放大只是让果更醒目，不改变诊断路径 |

## 6. 改动后验证

**A. 慢查询**（run.sh step 4 已内置）：`CREATE INDEX idx_val ON big(val); ANALYZE TABLE big;`
后同口径复测——EXPLAIN type=ref / key=idx_val / rows=1，Handler_read_rnd_next=0，
查询结果不变（19999）。三证齐 = 修好；只看「查询变快」不算（本量级体感不可靠）。

**B. 快照读**：它不是要「修」的缺陷，验证动作是把**语义**钉牢：A 提交事务后（或新开
连接）立即能读到 2（`fresh_read=2`）；若业务需要读到 B 的提交，出口是「读完即提交、
缩短事务」，或显式改用 READ COMMITTED（`SET SESSION transaction_isolation='READ-COMMITTED'`，
改动前先与维护者对齐口径——改隔离级别是行为变更，不进本 lab 的自动判据）。

健康对照（2026-11-06 真跑）：run.sh 全部 5 步「符合预期」，RUN-PASS 5/5、退出码 0；
断言维度：EXPLAIN-SCAN/HANDLER-SCAN（修复前红）与 EXPLAIN-IDX/HANDLER-IDX（修复后绿）
+ SNAPSHOT 三值，全部机器可判定。

## 7. 停止 / 升级条件（docs/71 §5 stop rules 对齐）

碰到任一条，停下来交维护者，不自行发挥：

1. `docker` 不可用，或 devbox-db 栈起不来 / mysql 容器连续两次不 healthy；
2. 同一验证命令连续两次失败（含 assert.sh 连红两次）；
3. `@@transaction_isolation` 不是 REPEATABLE-READ（镜像/版本行为漂移）；
4. EXPLAIN 的 type/rows 形态与本 lab 现场不符（如建了索引仍 ALL）——先按 §3 分支排查，
   排不出登记 UNVERIFIED 交维护者；
5. 需要改动 `db/examples/T-001-slow-query-repeatable-read/` 之外的仓库文件（含
   db/scripts/、compose 文件）才能继续；
6. **收尾纪律**：任何退出路径都要执行 `bash db/scripts/down.sh`（连 -v 清卷），
   期间不并发跑其他 db 任务；
7. 验收判据有歧义。

## 8. last verified 与 UNVERIFIED 表

**last verified: 2026-11-06**，devbox-db compose 栈（mysql:8.4.13、compose 项目名
devbox-db、docker on linux/amd64）。`assert.sh` 连跑 2 次均 ASSERT-PASS、退出码 0，
结论一致；repro.sh rc=1（证据坐实纪律）、run.sh RUN-PASS 5/5；验证后已执行
`bash db/scripts/down.sh` 收尾。

| 判据 | 状态 | 原因 | 谁来补验 |
|---|---|---|---|
| 壁钟时间（全扫 vs 索引）在更大行数（百万级）下的对照 | UNVERIFIED | 本 lab 判据钉扫描量证据链，壁钟在 2 万行量级不可靠（§5.2 H4） | 维护者若要「慢」体感，做百万行变体时补 |
| READ COMMITTED 下同一时序的 second_read=2 | UNVERIFIED | 改隔离级别属行为变更，未进本 lab 自动判据（§6 B） | 做隔离级别对比变体 lab 时补 |
| `information_schema.INNODB_TRX` 长事务排查形态 | UNVERIFIED | 本 lab 用双会话最小现场，未起长事务监控 | 做长事务变体 lab 时补 |
| multi profile（mysql2 主从）下的复制延迟表现 | UNVERIFIED | 本 lab 只用默认 profile 单实例 | 做主从变体 lab 时补 |
| challenge/ 档的学习者实测用时与卡点 | UNVERIFIED | faded 档按定义不给判读，无真人试做记录 | 首位完成 challenge 的学习者回填 |

## 9. 素材来源

- **类型②实验**：§1/§4 全部现象均为 2026-11-06 在 devbox-db compose 栈内真跑所得，
  复现命令即 §1 与 `repro.sh`；输出已按 docs/72 §2 归一化（rows 统计估计 → 量级断言），
  不含内网信息。
- **来源：S-07**（docs/24-G3素材池.md）：「CI 全绿 ≠ 教学质量达标」的 db 变体——
  §1 症状一（结果永远正确、扫描路径全错）与 §5.2 H4（结果自洽 ≠ 走对路径）都是该
  素材的应用；症状二（语义级「异常」不报警）同理。
- **来源：S-06**（docs/24-G3素材池.md）：「探测失败被误读为服务问题」——§2 检查 1、
  §3 Q0 分支与 §4.0 的 wait-ready 覆盖文件坑判读都遵循该素材的纪律。
