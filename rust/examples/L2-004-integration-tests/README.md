# L2-004-integration-tests


## 考点
对应 KP-RS-L2-04：从独立的 `tests/` crate 验证库的公开行为。
看到集成测试通过公开 API 得到规范化结果，说明测试与库内部实现隔离。

## 易错点
集成测试不能直接引用库的私有项，尝试访问会编译失败。
只通过公开接口验证可见行为，让私有实现保持可替换。

## 延伸
为索引库的公开查询方法编写跨模块集成测试。
验证 API 返回值与错误行为，而不绑定内部数据结构。

## 复现
TAG=latest scripts/run-example.sh rust L2-004-integration-tests
