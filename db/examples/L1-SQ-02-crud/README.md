<!-- coverage: pending -->

# L1-SQ-02-crud · CRUD 与 UPSERT

## 考点
- 对比 UPSERT 前后行数，检查 `INSERT OR IGNORE` 与 `INSERT OR REPLACE`。
- 用 `UPDATE ... FROM` 从另一张表补充数量，再用 `RETURNING` 输出更新行。
- 排序后的最终业务键结果验证重复键没有额外插入。

## 为什么这么写
语句串联在单独的 SQLite 文件中，结果包含每一步的行数与最终状态，能区分更新、忽略和替换的效果。

## 易错点
- `REPLACE` 是冲突时删除再插入，不等同于原地更新。
- 只看 UPSERT 后计数无法确认冲突行字段已更新，因此同时检查最终值。

## 依赖服务
`toolbox`

## 命名空间
`/tmp/l1-sq-02-crud.db`
