# L2-009-module-layers

<!-- coverage: pending -->

## 考点
对应 KP-JV-L2-09：命令入口依赖业务接口，业务服务不依赖控制台或进程退出。
另一包可调用公开服务并获得固定命中，而编译器拒绝其直接引用 package-private 实现，说明公开边界有效。

## 易错点
业务层混入 System.exit 或控制台副作用，会让单元调用依赖 CLI 并可能终止进程。
业务层返回结果或抛领域异常，由入口统一映射输出与退出码；实现类保持非公开。

## 延伸
为公开服务增加存储接口，并用内存实现独立验证查询行为。
继续检查 CLI、解析、索引与存储之间的依赖方向。

## 复现
TAG=latest scripts/run-example.sh java L2-009-module-layers
