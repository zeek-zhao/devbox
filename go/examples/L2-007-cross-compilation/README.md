# L2-007-cross-compilation

<!-- coverage: pending -->

## 考点
对应 KP-GO-L2-07：使用 GOOS 和 GOARCH 为非宿主平台构建 Go 程序。
看到 linux/arm64 目标构建成功且产物格式被识别，说明掌握交叉编译。
用例只检查产物，不会尝试在宿主机运行它。

## 易错点
交叉编译产物不能在宿主机直接执行，因为它面向不同的操作系统或处理器架构。
只验证目标文件格式，并把产物写入临时目录，避免误执行或污染用例目录。

## 延伸
为 darwin/arm64 和 windows/amd64 分别设置 GOOS、GOARCH 并构建。
进一步为多个目标平台生成发布产物，并按目标平台组织文件名。

## 复现
TAG=latest scripts/run-example.sh go L2-007-cross-compilation
