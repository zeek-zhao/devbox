## 考点
用 `g++` 按 C++20 编译 `hello.cpp`，验证 `<string_view>`、`<numeric>` 的标准库入口及基本算法。
程序编译为 `/tmp/devbox-hello-cpp` 并运行，输出检查 `string_view` 长度和 1 到 100 的求和。

## 运行
在仓库根目录执行：`TAG=latest scripts/run-example.sh cpp hello`。

## 易错点
直接用默认编译标准可能无法启用目标特性；脚本通过 `-std=c++20` 明确指定标准。
如需换编译器，设置 `CXX`；编译器必须支持 C++20。
