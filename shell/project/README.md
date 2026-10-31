# 部署与巡检工具集

Bash 5.2 工具集：严格模式、手写长选项解析、原子发布、flock 防重入、
并行巡检与确定性报告。只使用本地命令，不下载依赖、不读取 Git 元数据。

```text
project/
  src/main.sh          主入口
  lib/common.sh       参数、诊断、信号与临时目录清理
  lib/commands.sh     deploy / inspect / report / self-check
  tests/commands.bats BATS 1.10.0 测试
  build.sh            bash -n + shellcheck 0.9.0 warning 门禁
  check-runtime.sh    只读挂载到 runtime，逐字比较固定输出
  COVERAGE.md         全部 54 个用例的真实落点
  build/              忽略的自检产物
```

从仓库根目录执行（镜像必须已在本地，不 pull）：

**构建**
```bash
docker run --rm --user "$(id -u):$(id -g)" -v "$PWD:/work" -w /work ghcr.io/zeek-zhao/devbox-shell:${TAG:-latest} bash shell/project/build.sh
```

**运行**
```bash
bash shell/project/src/main.sh --self-check
```

**测试**
```bash
docker run --rm --user "$(id -u):$(id -g)" -v "$PWD:/work" -w /work ghcr.io/zeek-zhao/devbox-shell:${TAG:-latest} bats shell/project/tests
```

宿主可直接运行 `bash shell/project/build.sh`；缺少 shellcheck 时，
脚本会用本地 shell 镜像执行同一门禁，不联网下载。
`bash shell/project/check-runtime.sh` 会在缺少构建标记时先构建，再验证 runtime；
镜像不在本地则明确 skip。构建可重复执行，输出只落在被忽略的 `build/`。

## 命令契约

`deploy --target DIR [--name NAME]` 发布固定服务配置及 SHA256SUMS。
NAME 为 1–32 个 ASCII 字母、数字、连字符，首字符必须为字母，默认 demo。
推荐把 target 放在 `mktemp -d` 创建的临时目录内；target 由调用者持有，
不会随命令退出删除。内部 staging 在同一文件系统上创建、原子 rename，
退出或 INT/TERM 时清理。锁文件保留（删除锁文件会破坏并发互斥）。
相同配置再次部署输出 unchanged，不重写文件；已存在的配置漂移或校验失败会拒绝部署，
不自动覆盖。并发部署立即失败，不进行无界等待。

`inspect --target DIR [--config FILE]` 并行检查文件数量、SHA256 完整性、
递归目录布局；每个 worker 独立输出，全部 wait 后排序为两列 TSV。
可选 JSON 配置使用 jq 检查 `.policy.services` 中是否有
`{"name":"demo","enabled":true}`；该项需要 shell 镜像的 jq。
runtime 固定自检不使用 JSON。检查失败仍完整输出全部结果，退出 1；
配置/参数错误退出 2；信号 INT/TERM 分别退出 130/143，先回收 worker 再删临时目录。
worker 用 setsid 隔离进程组，清理信号同时覆盖其外部子进程；
错误信息独立保留在 stderr，不混入 TSV。

`report --input FILE` 或 `report -f FILE` 验证两列 TSV，拒绝空输入、
重复检查名、多余列和非 PASS/FAIL 状态；排序输出文本表格及总计。
报告中的 FAIL 是数据，不使 report 本身失败。`--help` 输出用法。
所有正常输出不含时间、随机值、绝对路径或 PID；stderr 是诊断流。

`--self-check` 在独立临时目录中部署两次、巡检、报告，并比较固定 TSV。
不依赖调用者当前目录，runtime 将整个 project 以只读挂载。
