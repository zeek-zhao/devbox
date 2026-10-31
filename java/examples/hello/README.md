## 考点
用 JDK 21 的 `java Hello.java` 单文件源码模式运行，无需先调用 `javac`。
验证 Java 21 的 `record`、运行时 feature 版本、距离计算和循环求和。

## 运行
在仓库根目录执行：`TAG=latest scripts/run-example.sh java hello`。

## 易错点
镜像需要安装 JDK 21，并确保 `java` 在 `PATH` 中；仅设置 `JAVA_HOME` 而未配置路径可能找不到命令。
单文件源码模式要求 Java 11 或更高版本，本用例还使用 Java 16 引入的 `record`。
