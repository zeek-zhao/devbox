<!-- coverage: exempt DB-06 使用部署预置的 PostgreSQL 连接身份，仅在业务 schema 内存取报表；项目不管理 PostgreSQL 全局角色或授权策略。 -->

# L1-PG-08-schema-grant · schema 与权限

## 考点

- `search_path` 是当前会话设置，控制未限定 schema 名称的解析顺序。
- `USAGE` 允许访问 schema 名称空间，不等于拥有其中表的 `SELECT` 权限。
- 实际切换到受限角色后，跨 schema 读表应被 PostgreSQL 拒绝。

## 为什么这么写

每次重建本例数据库和专属角色；同一会话设置并读取 `search_path`，再 `SET ROLE` 执行真实查询并捕获权限异常，避免跨会话断言或只检查权限元数据。

## 易错点

- `SET search_path` 不会持久化到另一个连接。
- 只授予 schema 的 `USAGE`，而不给表 `SELECT`，访问表仍应失败。
- 角色名是全局对象，因此运行开始时先删除本例的专属角色。

## 依赖服务

`postgres`

## 命名空间

`db_l1_pg_08_schema_grant`
