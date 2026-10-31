<!-- coverage: pending -->

# L1-PG-07-serial-sequence · 序列与自增

## 考点

- `SERIAL` 是 PostgreSQL 的序列加默认值等对象组成的语法糖；`IDENTITY` 是标准 SQL 身份列语法。
- `nextval` 在事务回滚后不会退回已分配的序列值。
- `currval` 返回当前会话该序列最近分配的值，不会替代跨会话的全局查询。
- 两种自增定义均能为新行生成标识。

## 为什么这么写

先在事务中取一次 `SERIAL` 序列值再回滚，随后再次取值并插入；输出能直接看到回滚造成的序列空洞。另用 identity 表插入一行展示标准写法。

## 易错点

- 序列值不是事务性数据，回滚不会让 `nextval` 重复返回刚分配的值。
- 不要把实际表的自增 ID 当作跨运行固定输出；本例每次先重建专属数据库。
- `SERIAL` 与 `IDENTITY` 的创建机制不同，不应把前者称为标准 identity 列。

## 依赖服务

`postgres`

## 命名空间

`db_l1_pg_07_serial_sequence`
