
# L4-05-multi-tenant · 多租户隔离

## 考点
- 独立数据库方案为 A 账号只授权 A 库，实际探测 B 库并确认访问被拒。
- 独立 schema 方案实际执行跨 schema 探测并捕获权限拒绝，而非只在查询中添加租户过滤。
- 共享表启用 PostgreSQL RLS：A 角色看不到 B 行，跨租户更新影响行数为 0。

## 为什么这么写
MySQL 库边界、PostgreSQL schema 权限和共享表 RLS 是三种不同隔离层级。共享表策略基于 `current_user`，而不是应用可自行改写的 `tenant_id` 参数；测试通过 `SET ROLE tenant_a` 以非表所有者身份执行。

## 易错点
- PostgreSQL 表所有者/超级用户可绕过普通 RLS，因此例子切换到无 `BYPASSRLS` 的租户角色并启用 `FORCE ROW LEVEL SECURITY`。
- 把 `WHERE tenant_id='A'` 写进 SQL 只是调用方过滤，不是权限隔离。
- 本例以专属数据库及 schema 命名空间管理数据，运行时不会删除 `devbox` 数据库。

## 依赖服务
`mysql`、`postgres`

## 命名空间
MySQL `db_l4_05_tenant_a` / `db_l4_05_tenant_b`；PostgreSQL `l4_05_tenant_a` / `l4_05_tenant_b`
