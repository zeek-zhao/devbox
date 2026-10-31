# L1-030-modules-visibility


## 考点
对应 KP-RS-L1-30：`mod` 组织模块，`pub`、`pub(crate)`、`pub(super)` 控制边界，`use` 缩短调用路径。
看到完整路径和导入短名均得到 `query:rust`、crate 内名称可读，说明公开接口能封装私有解析逻辑。

## 易错点
把私有项误当成默认公开 API，会导致跨模块访问编译失败，因为模块和成员都必须满足可见性限制。
只公开调用方必需项并明确路径；`normalize` 留在解析模块，`parse` 仅供父模块使用，入口只调用公开接口。

## 延伸
在毕业项目中为解析、索引、查询划分模块，外部调用只依赖稳定查询 API。
审查每个公开项的真实调用方，能缩小到 crate 或父模块的接口就缩小可见性。

## 复现
TAG=latest scripts/run-example.sh rust L1-030-modules-visibility
