# L2-010-dependency-integration

<!-- coverage: pending -->

## 考点
对应 KP-L2-10：干净配置通过 `find_package(Threads REQUIRED)` 查找依赖，并在目标上链接 `Threads::Threads`。
看到 `dependency: Threads found` 且可选功能关闭时输出 `optional: off`，说明依赖声明和开关生效。

## 易错点
只靠开发机手动安装或隐式链接，容易让干净环境配置失败。
把依赖写进 CMake 目标，并用显式 option 控制可选功能，避免依赖本机偶然状态。

## 延伸
可以为可选后端增加独立依赖，并用目标级条件链接使关闭选项时不查找它。
再在干净容器里分别配置依赖可用与不可用的构建矩阵。

## 复现
TAG=latest scripts/run-example.sh cpp L2-010-dependency-integration
