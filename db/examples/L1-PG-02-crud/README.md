
# L1-PG-02-crud · CRUD 与 RETURNING

## 考点

- `INSERT ... ON CONFLICT` 原地更新冲突行，并以 `RETURNING` 输出修改后的值。
- `UPDATE ... FROM` 可把关联表的调整量用于更新。
- `DELETE ... USING` 支持按另一张表匹配删除目标行。

## 为什么这么写

每种修改语句都通过 PostgreSQL 的 `RETURNING` 输出实际受影响行；最终再按业务键排序查询，能区分变更结果与表中最终状态。

## 易错点

- `ON CONFLICT` 只更新明确指定的冲突行；不能把 UPSERT 和无条件新增混为一谈。
- `UPDATE ... FROM` 连接键应唯一，否则一行可能匹配多条来源记录。
- `DELETE ... USING` 的返回行没有顺序保证，本例只删除一行。

## 依赖服务

`postgres`

## 命名空间

`db_l1_pg_02_crud`
