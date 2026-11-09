# E-012-error-aggregate —— 批处理的失败聚合

<!-- coverage: exempt Shell 轨 E 段错误处理专题示例（E-012 失败聚合），面向错误处理教学，不接入毕业项目；排查指引将收录于 shell/docs/排查手册.md 错误处理章（该章由 M11-DOC-shell 卡统一落盘，先以本指向登记） -->

## 现象

批处理脚本 `for x in ...; do step "$x" || exit 1; done`：第一个失败就中断，
后面的项根本没跑；每次只能修一个、再跑一轮、再修一个——一批 100 项要跑
100 轮才能把失败清单凑齐。反过来 `|| true` 跑完全部，又把失败全吞了。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh shell E-012-error-aggregate
# 或直接在 devbox-shell 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/shell/examples/E-012-error-aggregate \
  ghcr.io/zeek-zhao/devbox-shell:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：逐项记录 ok/failed，gamma 失败后 delta 照常执行；
汇总行 `failed=2 passed=2`，整体退出码 1，末行是完整失败清单。

## 为什么这样处理

- 逐项接住失败（`task "$item" || rc=$?`）并记录，不中断批处理：
  一轮跑完拿到完整失败清单，修复轮次从 N 降到 1。
- 批处理「有失败」本身是一个失败事实：run_batch 以非零上抛，
  上层（CI、调用方）能看到这批不干净——聚合不等于吞掉（与 E-008 一致）。
- 失败清单带上各自原始码：beta(rc=3)、gamma(rc=2) 是两类问题，
  下一步处理按码分派（E-001/E-003）。

## 反例

- `step || exit 1`：一失败就断，损失后面所有项的执行机会与信息。
- `step || true` 跑完只报 done：失败被聚合语义吞掉，假绿。
- 只报 failed=2 不报清单：排障还得重跑一轮才知道是哪两项。
