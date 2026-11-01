# L2-10-conn-security · 连接安全

<!-- coverage: exempt DB-06 是仅供本地 Compose 网络运行的教学服务，不提供外部连接端点；TLS 终止和数据库传输策略由部署层负责。 -->

## 考点

密码策略、TLS 连接、禁止超级用户远程、连接串不入库

## 判据（验收按这一条核对）

输出 TLS 握手状态与弱密码被拒

## 为什么这么写

共享 PG 只读检查 SSL 开关；另起临时 PG 以证书验证 TLS 握手，并加载 passwordcheck 扩展验证弱密码拒绝，不改共享服务配置。

## 易错点

- 自签证书包含容器 DNS 名 SAN，客户端用 verify-full 验证身份。
- 容器私钥需由 postgres 用户持有且权限为 0600。

## 依赖服务

`postgres`

## 命名空间

`l2_10_conn_security`（用例开始时必须自己清理，保证可重复运行）

## 契约

- `run.sh` 跑在**宿主**上，用 `scripts/lib/common.sh` 里的 `tb` / `mysql_file` / `psql_file` / `redis_file` / `sqlite_file` / `py_file` 进容器
- stdout 必须确定：显式 `ORDER BY`、不打时间戳、不打耗时
- 交付前必须自己跑一次 `bash db/scripts/run-example.sh db L2-10-conn-security --update` 生成 `expected.txt`，
  并**人工确认输出确实体现了上面的考点**（不是「跑通就算」）
- 本用例与 DB-06 的覆盖处置及理由见顶部声明。
