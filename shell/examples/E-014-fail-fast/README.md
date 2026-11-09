# E-014-fail-fast —— 前置校验与快速失败

<!-- coverage: exempt Shell 轨 E 段错误处理专题示例（E-014 前置校验快速失败），面向错误处理教学，不接入毕业项目；排查指引将收录于 shell/docs/排查手册.md 错误处理章（该章由 M11-DOC-shell 卡统一落盘，先以本指向登记） -->

## 现象

脚本跑到第 5 步才撞上"环境变量没配/工具没装"：前 4 步的副作用已经发生
（文件写了、服务重启了），报错却只说第 5 步失败——失败来得晚、现场被污染、
原因还模糊。缺失一个必配项本来应该在 0 秒内被拦下。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh shell E-014-fail-fast
# 或直接在 devbox-shell 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/shell/examples/E-014-fail-fast \
  ghcr.io/zeek-zhao/devbox-shell:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：missing-env 场景被校验拦下（rc=2，指名缺失项，
work_done=0）；env-ok 场景正常开工（rc=0，work_done=1）；
盲跑对照在半路失败（rc=3，work_done=0）。

## 为什么这样处理

- 校验集中在一个函数、在任何副作用之前执行：一次看完所有前置的缺失情况，
  而不是每修一个跑一轮再撞下一个。
- 第一个缺失即停并**指名缺失项**：`validate: missing ENV_API_URL`
  是可执行的动作项，不是一句 "env error"。
- 校验失败用 usage 类别（rc=2）：这是调用方环境的 bug，重试无意义（E-001）。

## 反例

- 校验散落在各个步骤里：检查点遗漏一处，失败就顺延到那一处才爆。
- 只校验不指名：报 "missing env"，排障的人挨个变量猜。
- 校验通过就以为万事大吉：不做实际工具的探活（--version / 干跑），
  假前置真故障。
