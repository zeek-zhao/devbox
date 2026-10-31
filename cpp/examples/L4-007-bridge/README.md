# L4-007-bridge

<!-- coverage: pending -->

## 考点

对应 KP-L4-07：把抽象与实现分离成两个独立继承体系，二者可独立扩展。

可观察判据：抽象侧持有实现侧指针，两种抽象 × 两种实现共四种组合各输出固定标签。

## 为什么这样写

`main.cpp` 第 7–21 行是数据来源的实现层次，第 23–51 行是报告的抽象层次，`Report` 持有 `shared_ptr<const Source>`。
两种报告的 `render()` 都通过 `Source&` 虚派发读取来源，不为四种组合各派生一个类。
第 54–64 行创建全部四种组合，再通过 `unique_ptr<Report>` 调用虚函数。
若去掉实现桥接并将来源写死为 `file`，`text/memory` 和 `json/memory` 两行都会变成文件标签；更换报告类型只改变格式前缀。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh cpp L4-007-bridge
```
