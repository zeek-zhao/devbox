# E-010-null-semantics —— NULL 语义陷阱：不报错但结果错

<!-- coverage: exempt db 轨 E 段错误处理专题示例（E-010 NULL 语义陷阱），面向错误处理教学，不接入毕业项目；排查指引将收录于 db/docs/排查手册.md 错误处理章（该章由 M11-DOC-db 卡统一落盘，先以本指向登记） -->

## 主题映射

语言轨错误处理 E 段「哨兵值与空值边界」（`E-009-errno-boundary`）主题的 db 轨落地：
NULL 不是值而是「未知」，聚合会跳过它、三值逻辑会吞掉比较——这一类 bug
**从不报错，只是悄悄给出错的结果**，比崩溃更难排查。

## 现象

五张订单里两张 `amount` 为 NULL、两张 `region` 为 NULL：`COUNT(*)` 与
`COUNT(amount)` 差 1；南区全是 NULL 单，`SUM` 返回 NULL 而不是 0，
下游拿去算总账变成 NULL 传染；`WHERE region = NULL` 恒不匹配（0 行），
`NOT IN` 列表里混进一个 NULL 后整个谓词对每一行都是 UNKNOWN（0 行）——
报表「变空」而不是报错。

## 复现命令

```bash
bash db/scripts/run-example.sh db E-010-null-semantics
# 或单独跑断言：
bash db/examples/E-010-null-semantics/assert.sh
```

## 期望输出

与 expected.txt 逐行一致：`count rows=5 amount_non_null=2`、
`distinct_region=2`、`north_sum=100`、
`south_sum_is_null=yes south_sum_coalesced=0`、
`eq_null_matches=0 is_null_matches=2`、`avg_amount=150`、
`not_in_trap=0 not_in_fixed=3`。

## 为什么这样处理

- 计数先问清「数的是什么」：行数用 `COUNT(*)`，非空值个数用 `COUNT(col)`，
  两者混用是对账差异最常见来源。
- 空集聚合必须 `COALESCE(SUM(...), 0)` 收口：SQL 的 SUM 对空集返回 NULL，
  应用层的加法不会。
- NULL 判断只用 `IS NULL` / `IS NOT NULL`：`= NULL` 在三值逻辑下是 UNKNOWN，
  WHERE 里被当成假；`NOT IN` 前先保证列表与列都不含 NULL，或显式 OR 上
  `col IS NULL` 的业务语义。

## 反例

- `WHERE region = NULL`——永远 0 行，还得意于「查询没报错」。
- 把 `SUM` 结果直接进算术——一个 NULL 单让整笔汇总变 NULL。
- 用应用侧 `if not rows` 兜底 NOT IN 陷阱——0 行被当成「没数据」，
  而不是「谓词写错了」。

## 依赖服务

`mysql`

## 命名空间

`db_e_010_null_semantics`
