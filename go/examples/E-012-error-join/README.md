# E-012-error-join —— 并发错误聚合

<!-- coverage: exempt Go 轨 E 段错误处理专题示例（E-012 并发错误聚合），面向错误处理教学，不接入毕业项目；排查指引将收录于 go/docs/排查手册.md 错误处理章（该章由 M11-DOC-go 卡统一落盘，先以本指向登记） -->

## 考点

批量同步多个分片时，等待全部 worker 完成、收集所有错误，再用 `errors.Join` 聚合。聚合错误保留各成员身份，`errors.Is` 可以逐个匹配；并发结果需排序，保证输出可复现。

## 易错点

- 第一个错误就 `return` 会让其余失败失明，运维每轮只能发现一个坏分片。
- 手工拼 `multierror` 字符串会丢错误身份，`errors.Is` 无法继续判定。
- 真跑对照：对同一组两个失败分片，首错即返回只观察到 1 个；收集完再聚合能观察到 2 个。整个失败集合以 stdout 数据呈现，样例进程仍以 0 退出。

## 复现

```bash
TAG=latest bash scripts/run-example.sh go E-012-error-join
# 或直接在 devbox-go 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/go/examples/E-012-error-join \
  ghcr.io/zeek-zhao/devbox-go:latest bash assert.sh
```

逐行输出应与 `expected.txt` 一致：聚合错误文本按分片号稳定排列，`errors.Is` 对 `ErrDisk`/`ErrAuth` 成立、对非成员不成立，单错误仍可聚合，空集合得到 nil。

## 延伸

- `errors.Join` 的聚合错误实现 `Unwrap() []error`，只增加结构，不破坏成员判定。
- goroutine 完成顺序不定，聚合前按分片号排序，避免相同故障产生不同输出。
