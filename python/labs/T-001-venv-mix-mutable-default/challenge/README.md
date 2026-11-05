# T-001-venv-mix-mutable-default · faded 挑战档

> 规则（docs/72 §4.3）：这里只给触发症状与可用工具清单，不给判读。
> 请先自己按 WALKTHROUGH 的 §4.1 结构（触发症状 / 前 60 秒三条只读检查 / 互斥决策树 /
> 逐行判读 / 改动后验证）写一遍，再对照 [SOLUTION.md](SOLUTION.md)。

## 触发症状

同事报障：`main.py` 在他机器上「import 不了包」，但另一台环境完全一样的机器却跑得好好的；
你自己复跑时还注意到程序的输出有两行列表长得一模一样，很可疑。devbox-python 镜像内直跑：

```bash
docker run --rm -v "$PWD":/w -w /w ghcr.io/zeek-zhao/devbox-python:latest \
  bash python/labs/T-001-venv-mix-mutable-default/repro.sh
```

以 `ModuleNotFoundError: No module named 'myproj'` 收场，退出码 1；输出里
`cart call1=['apple', 'banana']` 与 `cart call2=['apple', 'banana']` 两行完全相同。

## 你的任务

1. 先排除「程序根本没跑起来/环境探测失败被误读为代码问题」分支；
2. 判断「import 失败」与「两行列表相同」分别属于环境维度还是代码维度，各用至少一个
   工具/检测器钉到证据（import 失败要给出串味通道；列表相同要给出静态定位）；
3. 给出两个缺陷的修复与修复后的验证证据（行为 + 静态复查都要）。

## 可用工具清单（均在 devbox-python 镜像内，宿主上没有）

- `python3 -m venv`（lab 的 repro.sh 已搭好 venvA/venvB，venvA 里装了占位包 myproj）
- `python3 -m pip`（系统层受 PEP 668 约束；venv 内不受）
- `ruff check`（默认规则集 + `--select` 可指定 bugbear 等扩展规则族）
- 解释器自省：`sys.executable` / `sys.path` / `myproj.__file__`（如能 import 到的话）
- 同目录 `repro.sh` / `run.sh` / `assert.sh` 可作对照（先别看 WALKTHROUGH）

## 提交判据

`bash assert.sh` 输出 ASSERT-PASS；你的判读文档里至少有 1 个 predict–observe–explain
点与 2 条被否决的假设。
