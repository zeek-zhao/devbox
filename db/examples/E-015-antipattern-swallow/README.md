# E-015-antipattern-swallow —— 反模式对照：autocommit 滥用 + 吞错 = 半套落库

<!-- coverage: exempt db 轨 E 段错误处理专题示例（E-015 autocommit 滥用与吞错反模式对照），面向错误处理教学，不接入毕业项目；排查指引将收录于 db/docs/排查手册.md 错误处理章（该章由 M11-DOC-db 卡统一落盘，先以本指向登记） -->

## 主题映射

语言轨错误处理 E 段「反模式目录」（`E-015-antipattern-compare`）主题的 db 轨落地：
两个反模式各自只坏一半——autocommit 滥用让「一笔业务」碎成 N 个事务，
吞错让失败不可见——叠加后是「业务看似成功、账目悄悄少钱」的最坏组合。

## 现象

转账 = 扣款 + 入账两条 UPDATE。autocommit 连接里第一条已自动提交，
第二条撞 `1264`（Out of range，strict 模式）被 `except: pass` 吞掉：
函数正常返回，账面 `sum=170`——30 块钱无声蒸发，也没有任何报错痕迹。
同一场景换成显式事务 + 不吞错：失败即整体回滚，`sum=200` 一分不少，
错误带着 1264 如实上抛。

## 复现命令

```bash
bash db/scripts/run-example.sh db E-015-antipattern-swallow
# 或单独跑断言：
bash db/examples/E-015-antipattern-swallow/assert.sh
```

## 期望输出

与 expected.txt 逐行一致：反模式 `antipattern id=1 bal=70 id=2 bal=100`、
`antipattern sum=170 lost=30 reported=no`；正路 `handled err=1264
rollback=yes reported=yes`、`handled id=1 bal=100 id=2 bal=100`、
`handled sum=200 lost=0 consistent=yes`。

## 为什么这样处理

- autocommit 的隐藏代价是**事务边界消失**：两条 UPDATE 就是两个事务，
  「转账」这个原子概念在库里根本不存在；显式 `BEGIN`/commit 才能把业务
  原子性讲给数据库听。
- `except: pass` 不是「容错」，是**销毁故障证据**：错误被吞的那一刻起，
  下游所有对账差异都失去第一现场。捕获必须么处理（回滚/补偿/降级），
  么重新上抛。
- 验收口径用「总额不变」这类不变量，而不是「函数返回 None」：
  吞错反模式的输出一切正常，只有不变量能抓住它。

## 反例

- `except Exception: pass` 包住整个业务函数——不止吞数据库错误，
  连代码 bug 一起吞。
- 「日志里记一下就算处理」但继续往下走——调用方拿到的是假成功，
  日志与真实账目从此两张皮。
- 用 autocommit + 补偿语句「手动回滚」（再发一条 UPDATE 减回去）——
  补偿本身可能失败，一旦失败就没有任何回退手段。

## 依赖服务

`mysql`

## 命名空间

`db_e_015_antipattern_swallow`
