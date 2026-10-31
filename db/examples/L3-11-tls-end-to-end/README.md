# L3-11-tls-end-to-end · TLS 全链路

<!-- coverage: pending -->

## 考点

自签 CA、服务端证书、客户端校验、强制 TLS

## 判据（验收按这一条核对）

输出 TLS 连接状态与明文连接被拒

## 为什么这么写

临时 MySQL 强制 secure transport，客户端校验证书并读取 Ssl_cipher；再显式禁用 TLS 验证明文连接被服务端拒绝。

## 易错点

- 自签证书包含容器 DNS SAN，TLS 成功还必须校验证书链和主机名。
- 私钥/证书仅在临时目录和容器间传递，退出时清理，不进仓库。

## 依赖服务

`mysql,postgres`

## 命名空间

`l3_11_tls_end_to_end`（用例开始时必须自己清理，保证可重复运行）

## 契约

- `run.sh` 跑在**宿主**上，用 `scripts/lib/common.sh` 里的 `tb` / `mysql_file` / `psql_file` / `redis_file` / `sqlite_file` / `py_file` 进容器
- stdout 必须确定：显式 `ORDER BY`、不打时间戳、不打耗时
- 交付前必须自己跑一次 `bash db/scripts/run-example.sh db L3-11-tls-end-to-end --update` 生成 `expected.txt`，
  并**人工确认输出确实体现了上面的考点**（不是「跑通就算」）
- 完成后把上面的 `coverage: pending` 去掉，或保留 pending 并在 PR 里说明为什么
