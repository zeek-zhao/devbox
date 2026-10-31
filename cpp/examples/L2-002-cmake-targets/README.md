# L2-002-cmake-targets


## 考点
对应 KP-L2-02：CMake target 明确声明源文件、公开 include 路径和 target 专属编译选项。
配置、构建、安装后能运行安装的程序并找到公开头文件，即说明掌握本点。

## 易错点
依赖目录级全局编译选项会让无关 target 也被修改，且隐藏 target 自身需求。
把源文件、依赖和选项绑定到具体 target，并用 `PUBLIC` 暴露调用方需要的 include 路径。

## 延伸
可继续为 library 添加 `EXPORT` 与 package config，让另一个 CMake 工程通过 `find_package` 使用。
再比较 `PRIVATE`、`PUBLIC`、`INTERFACE` 对编译选项和头文件路径传播的影响。

## 复现
TAG=latest scripts/run-example.sh cpp L2-002-cmake-targets
