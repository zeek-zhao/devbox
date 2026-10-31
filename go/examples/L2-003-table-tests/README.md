# L2-003-table-tests

<!-- coverage: pending -->

## 考点
对应 KP-GO-L2-03：用表驱动测试和 t.Run 为多个查询输入创建具名子测试。
看到一条 go test 命令运行全部子测试，断言失败位置指向调用处，说明掌握了子测试与 helper。

## 易错点
辅助函数漏调 t.Helper 会把行号指向 helper，而不是出错的测试调用处。
在断言 helper 首行调用 t.Helper，让测试报告定位到实际调用位置。

## 延伸
为解析和查询接口补充空输入、缺失记录等边界用例，并让表项名称描述场景。
在子测试中比较共享断言 helper 与直接断言的可读性。

## 复现
TAG=latest scripts/run-example.sh go L2-003-table-tests
