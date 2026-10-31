# L1-MY-02-crud · 增删改查


> **这是 db 轨道的参照样板**。其它用例照这个结构写：
> `run.sh` 跑宿主 → `sql/*.sql` 用重定向喂进容器 → stdout 只有业务输出 → `expected.txt` 逐行对。

## 考点

- **`INSERT ... ON DUPLICATE KEY UPDATE` 到底更新了哪一行**：`id=2` 已存在时不能新增第 3 行，
  必须原地把 `qty` 从 5 改成 9。写成 `INSERT` 会撞主键报错，写成 `REPLACE` 会先删后插
  （自增 id 变了、触发器会再跑一次），这两条都不是「更新」。
- **`UPDATE` 的影响行数不等于匹配行数**：值没变时 MySQL 返回 `0 rows affected`，
  用「影响行数 > 0」判断「有没有这条记录」是错的。
- **`DELETE` 与 `TRUNCATE` 的差别**：`DELETE` 可回滚、走 binlog 行格式、能带 `WHERE`；
  `TRUNCATE` 是 DDL，隐式提交、不可回滚、重置自增。本用例只用 `DELETE`。
- **结果集顺序不保证**：不写 `ORDER BY` 时返回顺序取决于执行计划，
  这次对下次就错——所以 `query.sql` 里每一句都显式 `ORDER BY id`。

## 为什么这么写

- **SQL 放文件、用重定向喂进容器**，不在 shell 里拼字符串。原因：
  `docker compose exec` 再套 `bash -lc` 再套 SQL，引号要嵌套三层，
  一旦 SQL 里有单引号（`'apple'`）就必炸。用 `< sql/setup.sql` 把解析交给 mysql 客户端。
- **每个 sql 文件自带 `USE db_l1_my_02_crud;`**。`mysql_file` 不带 `-D`，
  显式写 `USE` 比在 shell 里传库名更不容易漏。
- **`AS new` 别名而不是 `VALUES(qty)`**：`VALUES()` 在 MySQL 8.0.20 起已废弃，
  8.4 上会告警；别名写法是官方推荐的替代。
- **先 `DROP DATABASE IF EXISTS` 再 `CREATE`**：保证反复跑结果一样，
  且不会误删别的用例的库（只删自己的命名空间）。

## 易错点

- 忘了 `USE`，语句跑到默认库 `devbox` 上——第一次能跑，第二次因为表已存在而失败。
- 用 `SELECT *` 代替显式列：表结构一改，`expected.txt` 就全错，而且看不出是结构变了还是数据变了。
- 把 `expected.txt` 用 `--update` 直接生成而不核对：这个用例的错误输出和正确输出
  只差 `qty` 的一个数字，肉眼不核就发现不了。

## 依赖服务

`mysql`

## 命名空间

`db_l1_my_02_crud`

## 运行

```bash
bash db/scripts/run-example.sh db L1-MY-02-crud
```

## 期望输出

```
== 初始两行
1	apple	3
2	banana	5
2
== UPSERT：id=2 的 qty 从 5 改成 9（不新增行）
1	apple	3
2	banana	9
2
== DELETE：删掉 id=1
2	banana	9
1
```
