# L2-09-least-privilege · 权限最小化


## 考点

应用账号只给 DML、禁 DROP、只读账号、角色继承

## 判据（验收按这一条核对）

输出应用账号执行 DDL 被拒的错误

## 为什么这么写

独立数据库和应用用户使授权范围可核验；权限失败按稳定的 MySQL 错误码 1142 判断，不依赖本地化文案。

## 易错点

- 先删旧用户再建库授权，避免重跑残留权限。
- DML 权限允许 UPDATE，但不包含 DROP。

## 依赖服务

`mysql`

## 命名空间

`l2_09_least_privilege`（用例开始时必须自己清理，保证可重复运行）

## 契约

- `run.sh` 跑在**宿主**上，用 `scripts/lib/common.sh` 里的 `tb` / `mysql_file` / `psql_file` / `redis_file` / `sqlite_file` / `py_file` 进容器
- stdout 必须确定：显式 `ORDER BY`、不打时间戳、不打耗时
- 交付前必须自己跑一次 `bash db/scripts/run-example.sh db L2-09-least-privilege --update` 生成 `expected.txt`，
  并**人工确认输出确实体现了上面的考点**（不是「跑通就算」）
- 完成后把上面的 `coverage: pending` 去掉，或保留 pending 并在 PR 里说明为什么
