<!-- coverage: exempt DB-06 的 MongoDB 仅保存可重建的行为日志，订单真相在 MySQL；项目无需 Mongo 副本集选举或读写一致性。 -->

# L1-MG-08-replica-concept · 副本集概念

## 考点
- 在共享栈的 MongoDB 单机模式调用 `replSetGetStatus`，断言服务端拒绝该命令。
- 用稳定错误码 `NoReplicationEnabled` 说明单机实例没有成员、选举或副本集状态。

## 为什么这么写
选择契约允许的 (a)：断言共享服务实际的 `NoReplicationEnabled`（code 76），不改共享 compose 配置，也不启动额外 Mongo 实例。单机模式下无法演示成员状态、读偏好或多数写关注。

## 易错点
- `NotYetInitialized` 与 `NoReplicationEnabled` 不同；当前共享 mongod 没有以 `--replSet` 启动，实际返回后者。
- 不能把“命令失败”泛化成成功，脚本只接受预期错误码，其他 OperationFailure 会继续报错。
- 不要尝试初始化共享实例，否则会影响其他用例。

## 依赖服务
`mongodb`

## 命名空间
`db_l1_mg_08_replica_concept`
