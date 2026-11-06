# E-011-structured-logging

## 现象
五条日志按 `级别 序号 event=名 键值对` 固定格式输出，ERROR 行自带
offset/code 上下文；演练用自增序号替代时间戳保证输出确定。

## 复现
```bash
TAG=latest bash scripts/run-example.sh cpp E-011-structured-logging
```

## 期望输出
```text
INFO #1 event=startup pid=static
INFO #2 event=index_load docs=100 terms=42
WARN #3 event=slow_query ms=950 query=join
ERROR #4 event=index_corrupt offset=16 code=3
INFO #5 event=shutdown clean=true
```

## 为什么
错误处理只到 catch 为止的话，线上问题仍然无解——catch 完打一句
「operation failed」等于没打。可观测性的最小闭环是：错误发生时输出
一条**结构化**日志（级别区分故障等级、事件名可检索、键值对携带定位
上下文、一行一事件可 grep）。字段位置固定，聚合系统才能按列解析；
时间戳是唯一不确定的输入，演练中用序号顶替，格式与策略不变。
区别于 L2-011（向调用方回传错误上下文）：这里讲的是错误落盘后的
排查面，两者合起来才是完整链路。

## 反例
`std::cout << \"error\" << std::endl;`——没有级别、没有上下文、
和其他输出混流；或者把上下文拼成自然语言句子（「打开 data/index.bin
第 16 行失败」）——机器无法聚合检索；或者 ERROR/INFO 混用，告警
系统按 ERROR 行数报障时全是噪声。

<!-- coverage: exempt 排障示例（错误处理演练），不落入任何毕业项目代码；豁免理由与错误处理章统一归档于 cpp/docs/排查手册.md（M11-DOC-cpp 卡落盘） -->
