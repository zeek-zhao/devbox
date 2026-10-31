# L2-001-local-module-replace

<!-- coverage: pending -->

## 考点
对应 KP-GO-L2-01：用 go.mod 定义两个本地模块，并用 replace 连接解析器模块。
看到本地模块成功构建、测试并输出解析结果，且无需联网或修改依赖缓存，说明掌握了 replace。

## 易错点
replace 目标路径错误会使模块解析失败。
使用仓库内相对路径，并在空缓存环境复跑，避免依赖本机缓存掩盖路径问题。

## 延伸
练习把本地模块拆成稳定的接口与实现，并由上层模块通过 replace 联调。
进一步将模块切换到版本化依赖时，比较 replace 与 go.work 的适用场景。

## 复现
TAG=latest scripts/run-example.sh go L2-001-local-module-replace
