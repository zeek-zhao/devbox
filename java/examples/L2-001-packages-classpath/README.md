# L2-001-packages-classpath

<!-- coverage: pending -->

## 考点
对应 KP-JV-L2-01：包名形成全限定名，classpath 必须指向包树根。
从临时输出根目录用 `app.Main` 启动并调用另一包的类，看到固定结果即掌握多文件查找。

## 易错点
类文件存在仍启动失败，因为 classpath 不是包树根或主类名不完整。
使用输出根目录和全限定类名，并把编译结果放在临时工作区。

## 延伸
将 CLI、索引和存储分别放入包，明确公开 API 与包内实现的边界。
继续探索 classpath 多目录和 JAR 的查找顺序。

## 复现
TAG=latest scripts/run-example.sh java L2-001-packages-classpath
