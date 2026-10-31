# L2-006-build-tags

<!-- coverage: pending -->

## 考点
对应 KP-GO-L2-06：用构建约束在默认实现与 diagnostic 实现之间选择源码文件。
看到默认构建输出 default、指定 diagnostic tag 的构建输出 diagnostic，说明两种构建分别选中了对应实现。

## 易错点
标签文件头位置或约束表达式错误会导致文件被忽略，而构建仍可能成功。
按 Go 语法把约束放在 package 声明之前并留空行，再分别构建两种 tag。

## 延伸
为诊断实现增加仅在指定 tag 下编译的辅助功能，并保持默认构建不依赖它。
进一步比较自定义 tag 与 GOOS/GOARCH 文件约束的组合效果。

## 复现
TAG=latest scripts/run-example.sh go L2-006-build-tags
