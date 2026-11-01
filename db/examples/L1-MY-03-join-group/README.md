# L1-MY-03-join-group · 多表连接与分组

<!-- coverage: pending -->

## 考点

INNER/LEFT 差异、NULL 与 COUNT(*) 区别、HAVING 过滤聚合、GROUP_CONCAT

## 判据（验收按这一条核对）

输出两段结果：LEFT JOIN 补 NULL 行、GROUP BY 后的聚合值

## 依赖服务

`mysql`

## 命名空间

`l1_my_03_join_group`（用例开始时必须自己清理，保证可重复运行）

## 契约

- `run.sh` 跑在**宿主**上，用 `scripts/lib/common.sh` 里的 `tb` / `mysql_file` / `psql_file` / `redis_file` / `sqlite_file` / `py_file` 进容器
- stdout 必须确定：显式 `ORDER BY`、不打时间戳、不打耗时
- 交付前必须自己跑一次 `bash db/scripts/run-example.sh db L1-MY-03-join-group --update` 生成 `expected.txt`，
  并**人工确认输出确实体现了上面的考点**（不是「跑通就算」）
- 完成后把上面的 `coverage: pending` 去掉，或保留 pending 并在 PR 里说明为什么
