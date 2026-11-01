# L2-12-data-integrity · 数据校验与修复


## 考点

双写校验、CHECKSUM TABLE、orphan 检测、修复脚本

## 判据（验收按这一条核对）

输出校验发现的孤儿行数与修复结果

## 为什么这么写

关闭外键检查只为制造一个确实存在的孤儿行，随后用 LEFT JOIN 检出并删除；CHECKSUM TABLE 仅在两张小 InnoDB 表上运行，输出不暴露环境相关校验值。

## 易错点

- FOREIGN_KEY_CHECKS 是会话级开关，不能把它当作修复手段。
- checksum 的值会因数据状态而变，只断言计算成功。

## 依赖服务

`mysql`

## 命名空间

`l2_12_data_integrity`（用例开始时必须自己清理，保证可重复运行）

## 契约

- `run.sh` 跑在**宿主**上，用 `scripts/lib/common.sh` 里的 `tb` / `mysql_file` / `psql_file` / `redis_file` / `sqlite_file` / `py_file` 进容器
- stdout 必须确定：显式 `ORDER BY`、不打时间戳、不打耗时
- 交付前必须自己跑一次 `bash db/scripts/run-example.sh db L2-12-data-integrity --update` 生成 `expected.txt`，
  并**人工确认输出确实体现了上面的考点**（不是「跑通就算」）
- 本用例在 DB-06 项目里按 B 类豁免，理由见 `db/project/COVERAGE.md`
