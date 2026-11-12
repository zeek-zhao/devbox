# T-001-slow-query-repeatable-read · 排障演练

coverage: exempt 排障演练目录（2026-11-12 由 db/labs/T-001-slow-query-repeatable-read/ 迁入 examples/）：由 .github/workflows/ci.yml 的 labs job 真跑 run.sh 与 assert.sh 验收，不接入毕业项目 COVERAGE 覆盖口径；scripts/run-example.sh 与 db/scripts/run-example.sh 的 --all 显式跳过 T-* 前缀，演练不作为普通用例比对。

- 演练入口：`bash db/examples/T-001-slow-query-repeatable-read/run.sh`
- 断言：`bash db/examples/T-001-slow-query-repeatable-read/assert.sh`（部分轨道无此文件，以 run.sh 内断言为准）
- 逐行判读：[WALKTHROUGH.md](WALKTHROUGH.md)
- 规范真本：[docs/72-排障演练规范.md](../../../docs/72-排障演练规范.md)
