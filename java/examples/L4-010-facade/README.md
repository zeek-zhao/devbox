# L4-010-facade

<!-- coverage: exempt 项目已有单一 Api 业务边界，CRUD 不需协调多个独立子系统；JSON 与快照各有固定入口，再增加门面只会转发现有接口 -->

## 考点

对应 KP-JV-L4-10：用单一入口封装子系统多个步骤，调用方不感知内部协作。

可观察判据：外观类顺序调用三个子系统，输出固定三行。

## 为什么这样写

`src/Main.java` 第 27–37 行的 `SearchFacade.run` 顺序调用 `Parser.parse`、
`Indexer.index`、`Renderer.render`，前一步的真实结果交给后一步，
而第 39–41 行的 `main` 只调用一个外观入口，不直接访问子系统。
三个子系统分别拆词、去重排序、拼接文本，各自产生一行输出。
若外观跳过索引而直接渲染拆词结果，第二行消失，
第三行变为 `render: patterns|java|java`；判据同时检验步骤顺序和数据协作。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh java L4-010-facade
```
