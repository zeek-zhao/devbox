# E-002-error-create —— 错误创建：结构化诊断与退出码

<!-- coverage: exempt Shell 轨 E 段错误处理专题示例（E-002 错误创建），面向错误处理教学，不接入毕业项目；排查指引将收录于 shell/docs/排查手册.md 错误处理章（该章由 M11-DOC-shell 卡统一落盘，先以本指向登记） -->

## 考点

失败诊断应走 `stderr`，格式包含脚本名和发生位置；退出码表达失败类别，成功路径不应输出诊断。本例的 usage 错误码为 2。

## 易错点

- `echo "错误!"` 打到 stdout 会污染业务管道；失败后 `exit 0` 或不带码的 `return` 会造成静默假绿。
- 诊断缺少位置（只说 `failed`）会让定位全靠猜。
- 真跑对照：同一诊断写到 stdout 会污染业务数据；走统一 `err()` 写 stderr 才能分离通道。错误码会被样例捕获并展示为期望数据，整个 `run.sh` 仍以 0 退出。

## 复现

```bash
TAG=latest bash scripts/run-example.sh shell E-002-error-create
# 或直接在 devbox-shell 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/shell/examples/E-002-error-create \
  ghcr.io/zeek-zhao/devbox-shell:latest bash assert.sh
```

逐行输出应与 `expected.txt` 一致：失败路径含标准化诊断 `main.sh: validate-name: name is empty` 和 `rc=2`，成功路径只有 `rc=0` 且无诊断。

## 延伸

- 统一出口 `err()` 固定使用 `<脚本名>: <发生地>: <发生了什么>`，诊断写 stderr，stdout 留给业务输出。
- `report` 只在确有诊断时打印诊断行，避免成功路径空行和噪声。
