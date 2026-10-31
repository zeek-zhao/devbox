# L2-012-package-resources


## 考点
对应 KP-PY-L2-12：通过 `importlib.resources` 从包中读取内置配置。
资源读取出固定模板和页大小而不依赖当前工作目录，说明掌握了该 KP。

## 易错点
把资源假设为普通文件路径会在打包运行时失效。
使用资源 API 读取；只有外部接口必须接收路径时才用临时路径上下文。

## 延伸
把报表模板作为包资源随分发包一起发布。
为需要路径的原生工具适配 `as_file` 临时路径上下文。

## 复现
TAG=latest scripts/run-example.sh python L2-012-package-resources
