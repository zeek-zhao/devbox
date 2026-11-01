# L1-MY-01-create-and-types · 建表与数据类型

<!-- coverage: pending -->

## 考点

定长/变长、整型宽度与 UNSIGNED、DECIMAL 精度、ENUM vs VARCHAR、字符集与排序规则

## 判据（验收按这一条核对）

查询 information_schema 输出 4 张表的列类型清单，含 DECIMAL(10,2) 与 utf8mb4

## 依赖服务

`mysql`

## 命名空间

`l1_my_01_create_and_types`（用例开始时必须自己清理，保证可重复运行）

## 契约

- `run.sh` 跑在**宿主**上，用 `scripts/lib/common.sh` 里的 `tb` / `mysql_file` / `psql_file` / `redis_file` / `sqlite_file` / `py_file` 进容器
- stdout 必须确定：显式 `ORDER BY`、不打时间戳、不打耗时
- 交付前必须自己跑一次 `bash db/scripts/run-example.sh db L1-MY-01-create-and-types --update` 生成 `expected.txt`，
  并**人工确认输出确实体现了上面的考点**（不是「跑通就算」）
- 完成后把上面的 `coverage: pending` 去掉，或保留 pending 并在 PR 里说明为什么
