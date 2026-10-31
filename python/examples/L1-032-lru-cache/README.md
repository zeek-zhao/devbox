# L1-032-lru-cache


## 考点
对应 KP-PY-L1-32：用 `functools.lru_cache` 缓存纯函数，并观察命中、未命中与清理。
固定调用后命中计数增加、列表实参被拒绝，说明理解缓存的键约束。

## 易错点
不可哈希实参会抛 `TypeError`，而缓存还会长期保留返回值并共享同一可变对象。
只缓存纯函数、确保实参可哈希，并在数据失效时显式调用 `cache_clear`。

## 延伸
对清洗规则或词项解析等纯计算比较缓存前后的命中率。
为缓存设置合理的 `maxsize`，并明确缓存失效与可变结果的所有权。

## 复现
TAG=latest scripts/run-example.sh python L1-032-lru-cache
