# Python 毕业项目：CSV 数据处理与报表

仅用 runtime 已有的标准库完成流式读取、清洗去重、分类聚合和确定性文本报表。
`src/` 不依赖 JSON、dataclass、pytest 等开发模块；这些知识点在 `tests/` 中验证。
金额以非负整数分存储，输入接受最多两位小数，避免浮点误差。

```text
project/
├── src/main.py              # CLI 入口
├── src/csv_report/          # 校验、聚合、表格、临时资源管理
├── tests/                   # pytest 与开发环境知识点验证
├── tests/fixtures/          # 包内固定 CSV 资源
├── build.sh                 # 离线 ruff / mypy --strict / pytest
├── check-runtime.sh         # runtime 固定输入逐字比对
├── COVERAGE.md              # 全部 51 个用例的实际代码落点
└── build/                   # 忽略的自检戳与输出
```

在仓库根目录执行（镜像必须已在本地，不下载依赖）：

```bash
# 构建（可重复；工具在 devbox-python 中运行）
bash python/project/build.sh
# 运行（固定数据，依次调用 clean / summary / report）
bash python/project/check-runtime.sh
# 测试（独立重跑 pytest）
docker run --rm --pull=never --network none --user "$(id -u):$(id -g)" -e PYTHONDONTWRITEBYTECODE=1 -e PYTHONPATH=/app/src:/app -v "$PWD/python/project:/app" -w /app "ghcr.io/zeek-zhao/devbox-python:${TAG:-latest}" python3 -m pytest -q tests
```

自定义输入：`PYTHONDONTWRITEBYTECODE=1 python3 python/project/src/main.py clean input.csv clean.csv`；
然后用 `summary clean.csv` 或 `report clean.csv` 查看聚合。`--help` 展示参数。
`python3 python/project/src/main.py --self-check` 也可直接运行，不依赖当前目录。

CSV 表头严格为 `date,category,amount`（允许 UTF-8 BOM 和字段两端空白）。
日期必须是有效的 `YYYY-MM-DD`；分类去空白并 `casefold()`；金额不接受负值、指数、
超过两位小数或非数字。忽略全空行，清洗按规范化后的完整记录去重且保留首次出现顺序。
`summary` / `report` 汇总传入文件的全部记录，不隐式去重。
非法记录报告行号并拒绝输出；`clean` 通过同目录临时文件原子替换，不破坏旧报表。
已有同名 `.tmp` 文件会明确失败，不接管其他写入者的文件。

表格按 Unicode 码点数量而非终端宽度计算列宽，分类排序固定；不依赖终端、时间、
随机数或 Git 元数据。自检使用独占 `/tmp/devbox-python-self-check` 目录，退出时清理；
同一文件系统并发自检会明确拒绝，runtime 容器各自隔离。
`build.sh` 无论从哪个目录启动都在项目内工作；失败时不保留成功戳。

覆盖检查：`bash scripts/coverage-check.sh --strict python`。COVERAGE 落点允许指向开发测试，
例如 JSON 往返、进程/线程结果一致性、枚举状态和 dataclass 期望数据，不在 runtime 导入它们。
