# E-002-constraint-catch —— 约束违反的捕获与归因（唯一 / 检查 / 外键）

<!-- coverage: exempt db 轨 E 段错误处理专题示例（E-002 约束违反的捕获与归因），面向错误处理教学，不接入毕业项目；排查指引将收录于 db/docs/排查手册.md 错误处理章（该章由 M11-DOC-db 卡统一落盘，先以本指向登记） -->

## 主题映射

语言轨错误处理 E 段「错误匹配与归因」（`E-003-error-match`）主题的 db 轨落地：
约束违反不是一种错误——唯一（1062）、检查（3819）、外键（1452/1451）各有码，
处理策略也不同（换键重写 / 修数据 / 先删子行）。

## 现象

一段「插入用户 + 下订单」的代码撞上约束违反时，如果把所有 `MySQLError` 当同一种失败
（统一重试或统一报错），就分不清「email 重复要换一个」和「age 为负是调用方 bug」。
本例对同一张表 / 一对表的四种约束违反逐个归因，最后用修正后的数据正常落库。

## 复现命令

```bash
bash db/scripts/run-example.sh db E-002-constraint-catch
# 或单独跑断言：
bash db/examples/E-002-constraint-catch/assert.sh
```

## 期望输出

与 expected.txt 逐行一致：四种违反各一行 `class=unique/check/foreign_key retryable=no`，
合法订单 `valid_order ok=1`，修正后 `insert_ok rows=1`。

## 为什么这样处理

- 约束违反一律 `retryable=no`：重试同一条数据只会再撞同一堵墙，处理动作是
  「改数据」或「改调用」，不是重试。
- 外键错误要分方向：1452（插入孤儿）修引用方，1451（删被引用父行）先处理子行。
  两者共用「外键」类别但修法不同，所以输出里保留方向信息（orphan / delete_parent）。
- 修正数据后正常落库（`insert_ok rows=1`）证明「捕获 → 归因 → 修正」闭环可用。

## 反例

- `except: pass` 把约束违反吞掉——用户以为注册成功，实际没有落库。
- 对 1062 做「重试 3 次」——同一条数据重试三次还是 1062，纯属浪费。
- 用报错文本匹配（`"Duplicate" in msg`）归因——文案不稳定，码 1062 稳定。

## 依赖服务

`mysql`

## 命名空间

`db_e_002_constraint_catch`
