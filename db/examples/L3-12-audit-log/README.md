# L3-12-audit-log · 审计与合规日志

<!-- coverage: exempt DB-06 的 Mongo 记录是应用级订单行为事件，不是数据库管理员操作审计；项目没有自管数据库原生审计插件或审计日志策略的职责。 -->

## 考点

general_log/审计插件、pgaudit 思路、profiler、操作留痕

## 判据（验收按这一条核对）

输出审计日志抓到的敏感操作条数

## 为什么这么写

用数据库内 AFTER UPDATE 触发器把敏感余额变更写入审计表，避免切换 MySQL general_log 或 Mongo profiler 这类全局开关。

## 易错点

- 触发器要在业务更新前创建，并只记录明确的审计事件。
- 审计表避免记录不必要的敏感值；断言按业务事件过滤并显式排序。

## 依赖服务

`mysql,mongodb`

## 命名空间

`l3_12_audit_log`（用例开始时必须自己清理，保证可重复运行）

## 契约

- `run.sh` 跑在**宿主**上，用 `scripts/lib/common.sh` 里的 `tb` / `mysql_file` / `psql_file` / `redis_file` / `sqlite_file` / `py_file` 进容器
- stdout 必须确定：显式 `ORDER BY`、不打时间戳、不打耗时
- 交付前必须自己跑一次 `bash db/scripts/run-example.sh db L3-12-audit-log --update` 生成 `expected.txt`，
  并**人工确认输出确实体现了上面的考点**（不是「跑通就算」）
- 本用例与 DB-06 的覆盖处置及理由见顶部声明。
