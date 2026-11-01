# L3-10-archive-cold-hot · 数据归档与冷热分离

<!-- coverage: exempt DB-06 的 Mongo 行为数据按固定业务日分集合，但没有独立对象存储、保留期迁移或冷读接口；项目不实现冷热存储生命周期。 -->

## 考点

按时间归档、分区交换、冷数据迁移、归档后查询

## 判据（验收按这一条核对）

输出归档前后热表行数

## 为什么这么写

使用 INSERT INTO ... SELECT 复制旧日期行到冷表，再按相同谓词删除热表数据；逐步输出热表前后和冷表行数。

## 易错点

- 归档插入与删除应放在事务中才能避免两步之间故障导致重复或丢失；本演示数据脚本可重跑且每次重建数据库。
- 用固定日期边界，不依赖当前时间。

## 依赖服务

`mysql`

## 命名空间

`l3_10_archive_cold_hot`（用例开始时必须自己清理，保证可重复运行）

## 契约

- `run.sh` 跑在**宿主**上，用 `scripts/lib/common.sh` 里的 `tb` / `mysql_file` / `psql_file` / `redis_file` / `sqlite_file` / `py_file` 进容器
- stdout 必须确定：显式 `ORDER BY`、不打时间戳、不打耗时
- 交付前必须自己跑一次 `bash db/scripts/run-example.sh db L3-10-archive-cold-hot --update` 生成 `expected.txt`，
  并**人工确认输出确实体现了上面的考点**（不是「跑通就算」）
- 本用例与 DB-06 的覆盖处置及理由见顶部声明。
