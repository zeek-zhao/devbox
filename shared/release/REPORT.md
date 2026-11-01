# RELEASE-FIX 交付报告

## 改了什么

所有交付文件均位于唯一授权路径 `shared/release/**`。公共约定要求根目录
`REPORT.md`，但本卡禁止写授权路径外的任何文件，因此本报告放在此处。
未对工作仓库执行暂存、提交、推送或打 tag；测试中的提交和 tag 仅发生在临时仓库。
接手时已有本卡相关的源码和测试修改，均保留并补强，没有回退他人改动。

| 文件（相对 shared/release） | 改动 |
|---|---|
| `src/git.js` | 捕获 Git 子进程 stderr；先查匹配 tag，只有查询成功且结果为空才返回 null；通过 remote get-url 解析 GitHub SSH / HTTPS 地址。 |
| `src/changelog.js` | 有仓库地址时生成完整 compare URL，无地址时保留纯文本标题与比较范围。 |
| `src/cli.js` | 保留接手时的修改：调用共享 repositoryUrl，移除旧的内部 remote 解析。 |
| `package.json` | test 脚本改为 `node --test test/*.test.js`，没有添加依赖。 |
| `test/git.test.js` | 离线验证无 tag、有 tag、前缀、不可达 tag、Git 缺失、非仓库及 remote 解析。 |
| `test/changelog.test.js` | 验证纯文本范围与完整 URL，保留排序、分组等原有断言。 |
| `test/e2e.test.js` | 验证 CLI 空 stderr、实际 CHANGELOG、SSH / HTTPS 精确 URL，以及 dry-run 三次字节一致。 |
| `README.md` | 说明首次发版降级、链接规则，并修正测试命令。 |
| `docs/01-核心概念.md` | compare 示例补全 owner/repo。 |
| `docs/02-快速上手.md` | 修正相对 compare 示例，说明无 remote 的纯文本行为。 |
| `REPORT.md` | 本卡的实测记录与边界说明，不应纳入提交。 |

瑕疵 2 选择 **(a)**：无 remote 时没有可靠的仓库地址，省略 Markdown 链接并显示
`v0.0.1...v0.1.0` 这类纯文本范围，不凭空猜测地址，也不增加配置负担。
无前一 tag 时，沿用已有范围起点 `<currentTag>^`。

瑕疵 1 不匹配 fatal 英文文本，也不吞掉所有退出码 128：
`git tag --list '<prefix>*'` 成功且为空才表示没有匹配发布 tag。
查询失败直接抛出；存在匹配 tag 时执行原来的 describe，失败也直接抛出。
`stdio: ['ignore', 'pipe', 'pipe']` 将 stderr 保留在异常中，由 CLI 的错误路径显式报告，
而不是让 execFileSync 先把 stderr 泄漏一次。没有使用 `2>/dev/null`。

## 判据与实测输出

### 0. Node 与改前基线

在 worktree 根目录执行：

```bash
export PATH="$HOME/.nvm/versions/node/v20.20.2/bin:$PATH"
node --version
```

```text
v20.20.2
```

改前基线使用 HEAD 的临时副本，不覆盖已有工作区改动：

```bash
baseline=$(mktemp -d /tmp/zr-baseline-XXXXXX)
git archive HEAD shared/release | tar -x -C "$baseline"
(cd "$baseline/shared/release" && set -o pipefail && node --test test/*.test.js 2>&1 | tail -20)
# 实测后删除该临时副本
```

```text
  ...
# Subtest: toml 按 section 和 key 精确替换
ok 41 - toml 按 section 和 key 精确替换
  ---
  duration_ms: 0.553133
  ...
# Subtest: json 缺少 version 字段时明确失败
ok 42 - json 缺少 version 字段时明确失败
  ---
  duration_ms: 0.325438
  ...
1..42
# tests 42
# suites 0
# pass 42
# fail 0
# cancelled 0
# skipped 0
# todo 0
# duration_ms 429.180757
```

### 1. 全部测试：42 → 59（相对 HEAD 新增 17 条）

```bash
export PATH="$HOME/.nvm/versions/node/v20.20.2/bin:$PATH"
cd shared/release
set -o pipefail
node --test test/*.test.js 2>&1 | tail -20
```

```text
  ...
# Subtest: toml 按 section 和 key 精确替换
ok 58 - toml 按 section 和 key 精确替换
  ---
  duration_ms: 0.48658
  ...
# Subtest: json 缺少 version 字段时明确失败
ok 59 - json 缺少 version 字段时明确失败
  ---
  duration_ms: 0.314087
  ...
1..59
# tests 59
# suites 0
# pass 59
# fail 0
# cancelled 0
# skipped 0
# todo 0
# duration_ms 789.579638
```

另外从根目录用本地 Vue 镜像里的 Node 22 实测 **package.json 的 npm test**：

```bash
docker run --rm --user "$(id -u):$(id -g)" -e HOME=/tmp \
  -v "$PWD:/work:ro" -w /work/shared/release \
  ghcr.io/zeek-zhao/devbox-vue:local \
  bash -c 'node --version && set -o pipefail && npm test 2>&1 | tail -20'
```

```text
v22.11.0
  ...
# Subtest: toml 按 section 和 key 精确替换
ok 58 - toml 按 section 和 key 精确替换
  ---
  duration_ms: 0.542544
  ...
# Subtest: json 缺少 version 字段时明确失败
ok 59 - json 缺少 version 字段时明确失败
  ---
  duration_ms: 0.30506
  ...
1..59
# tests 59
# suites 0
# pass 59
# fail 0
# cancelled 0
# skipped 0
# todo 0
# duration_ms 737.101079
```

新增测试名（相对 HEAD，包含接手时已有并保留的测试）：

| 文件 | 测试名 |
|---|---|
| git.test.js | 没有 tag 时 lastTag 返回 null 且不输出 stderr |
| git.test.js | 有匹配 tag 时 lastTag 返回最新 tag |
| git.test.js | 仅有不匹配前缀的 tag 时 lastTag 返回 null |
| git.test.js | 存在匹配 tag 但不可从 HEAD 到达时仍抛出 describe 错误 |
| git.test.js | git 不存在时 lastTag 不掩盖 ENOENT |
| git.test.js | lastTag 不掩盖非 git 仓库错误 |
| git.test.js | 没有 origin remote 时 repositoryUrl 返回空字符串 |
| git.test.js | repositoryUrl 不掩盖非 git 仓库错误 |
| git.test.js | repositoryUrl 将 SSH GitHub remote 转为 HTTPS URL |
| git.test.js | repositoryUrl 保留 HTTPS GitHub remote 并移除 .git |
| changelog.test.js | 没有仓库 URL 时 CHANGELOG 标题为纯文本而非相对 compare 链接 |
| changelog.test.js | 没有仓库 URL 时保留前一 tag 到新 tag 的纯文本范围 |
| changelog.test.js | GitHub 仓库 URL 生成完整 compare 链接 |
| e2e.test.js | 无 remote 时写入的 CHANGELOG 不含相对 compare 链接 |
| e2e.test.js | 无 remote 的 dry-run 发布计划保留纯文本范围且三次逐字节相同 |
| e2e.test.js | SSH GitHub remote 生成完整 CHANGELOG compare URL |
| e2e.test.js | HTTPS GitHub remote 生成完整 CHANGELOG compare URL |

### 2–3. 独立临时仓库：空 stderr、无 remote、完整 URL、三次字节一致

以下是实际执行的最终核验命令；全程离线，finally 清理临时目录。
CLI 没有 `plan` 子命令，使用默认 dry-run；其 stdout 只打印计划摘要，
因此用同一条 buildPlan 路径读取实际计划中的 CHANGELOG，未修改 CLI 输出契约。
err.txt 放在临时仓库外，避免重定向提前制造未跟踪文件而触发脏树安全门。

```bash
export PATH="$HOME/.nvm/versions/node/v20.20.2/bin:$PATH"
node --input-type=module <<'NODE'
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { execFileSync, spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { loadConfig } from './shared/release/src/config.js';
import { readCommits } from './shared/release/src/commits.js';
import { lastTag, repositoryUrl } from './shared/release/src/git.js';
import { buildPlan } from './shared/release/src/plan.js';
const cli = path.resolve('shared/release/src/cli.js');
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'zr-verify-'));
const cwd = path.join(tmp, 'repo');
fs.mkdirSync(cwd);
const git = (args) => execFileSync('git', args, { cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
try {
  git(['init', '-q', '-b', 'work']);
  git(['config', 'user.name', 'test']);
  git(['config', 'user.email', 'test@example.com']);
  fs.writeFileSync(path.join(cwd, 'VERSION'), '0.0.1\n');
  fs.writeFileSync(path.join(cwd, 'package.json'), JSON.stringify({ name: 'offline-fixture', version: '0.0.1' }));
  git(['add', '.']);
  git(['commit', '-q', '-m', 'feat: initial release']);
  const config = await loadConfig(cwd);
  const makePlan = () => buildPlan({ config, commits: readCommits({ cwd, from: lastTag(cwd), to: 'HEAD' }), currentVersion: '0.0.1', date: '2026-11-01', repoUrl: repositoryUrl(cwd), previousTag: lastTag(cwd) });
  const snapshots = [];
  for (let i = 0; i < 3; i += 1) {
    const result = spawnSync(process.execPath, [cli, '--cwd', cwd, '--date', '2026-11-01'], { encoding: 'utf8' });
    assert.equal(result.status, 0, result.stderr);
    assert.equal(result.stderr, '');
    assert.equal(lastTag(cwd), null);
    const plan = makePlan();
    assert.doesNotMatch(plan.changelog, /\]\(/);
    assert.match(plan.changelog, /^v0\.1\.0\^\.\.\.v0\.1\.0$/m);
    snapshots.push(Buffer.from(result.stdout + '\n' + plan.changelog));
    if (i === 0) {
      fs.writeFileSync(path.join(tmp, 'err.txt'), result.stderr);
      console.log('--- stderr ---');
      process.stdout.write(fs.readFileSync(path.join(tmp, 'err.txt')));
      console.log('CLI exit: ' + result.status);
      console.log('lastTag: ' + lastTag(cwd));
      console.log('--- no-remote dry-run CHANGELOG ---');
      process.stdout.write(plan.changelog);
    }
  }
  assert.deepEqual(snapshots[0], snapshots[1]);
  assert.deepEqual(snapshots[1], snapshots[2]);
  console.log('three runs byte-identical: true');
  console.log('MD5 (first 8 hex): ' + createHash('md5').update(Buffer.concat(snapshots)).digest('hex').slice(0, 8));
  assert.equal(git(['status', '--porcelain']).trim(), '');
  assert.equal(fs.existsSync(path.join(cwd, 'CHANGELOG.md')), false);
  console.log('dry-run leaves worktree clean: true');
  git(['tag', 'v0.0.1']);
  git(['commit', '-q', '--allow-empty', '-m', 'feat: next release']);
  for (const remote of ['git@github.com:owner/repo.git', 'https://github.com/owner/repo.git']) {
    if (git(['remote']).trim()) git(['remote', 'remove', 'origin']);
    git(['remote', 'add', 'origin', remote]);
    const heading = makePlan().changelog.split('\n').find((line) => line.startsWith('## '));
    assert.equal(heading, '## [0.1.0](https://github.com/owner/repo/compare/v0.0.1...v0.1.0) (2026-11-01)');
    console.log('--- ' + (remote.startsWith('git@') ? 'SSH' : 'HTTPS') + ' ---');
    console.log(heading);
  }
} finally {
  fs.rmSync(tmp, { recursive: true, force: true });
}
NODE
```

```text
--- stderr ---
CLI exit: 0
lastTag: null
--- no-remote dry-run CHANGELOG ---
# Changelog

本文件由 `npx @zeek/release` 生成，请勿手改。

## 0.1.0 (2026-11-01)

v0.1.0^...v0.1.0

### ✨ Features | 新功能
* initial release
three runs byte-identical: true
MD5 (first 8 hex): 4a54ecb5
dry-run leaves worktree clean: true
--- SSH ---
## [0.1.0](https://github.com/owner/repo/compare/v0.0.1...v0.1.0) (2026-11-01)
--- HTTPS ---
## [0.1.0](https://github.com/owner/repo/compare/v0.0.1...v0.1.0) (2026-11-01)
```

退出码 0。三份 Buffer 两两精确比较，不以散列代替字节断言。
展示的 MD5 为三次输出拼接后的前 8 位，不包含临时绝对路径。

### 4. 零依赖

根目录执行：

```bash
node -e 'const p=require("./shared/release/package.json");console.log(JSON.stringify(p.dependencies||{}))'
```

```text
{}
```

### 5. 格式化（纯 JS / JSON，未改 .sh）

按本卡要求直接使用 `:local` 镜像中的 Prettier，仅检查本卡变动的 JS / JSON，
没有启动 shell 或其他轨道的格式化容器：

```bash
docker run --rm --user "$(id -u):$(id -g)" -e HOME=/tmp \
  -v "$PWD:/work:ro" -w /work ghcr.io/zeek-zhao/devbox-vue:local \
  prettier --check --ignore-path /work/.prettierignore \
  shared/release/src/git.js shared/release/src/changelog.js \
  shared/release/src/cli.js shared/release/test/git.test.js \
  shared/release/test/changelog.test.js shared/release/test/e2e.test.js \
  shared/release/package.json
```

```text
Checking formatting...
All matched files use Prettier code style!
```

退出码 0。`git diff --check -- shared/release` 也实际执行，输出为空、退出码 0。

## 真接入 vs 豁免

本卡不是 L4 / PROJ，也没有轨道用例或覆盖表变更，因此该表不适用。
未增加 pending / exempt，不适用轨道 `run-example.sh` 与 `coverage-check.sh`。
实际验收使用发布工具全量 Node 测试、独立临时仓库复现和 Prettier。

## 我没做的事 / 已知不足

- 未跑 CI、全仓库总闸或其他轨道测试；本卡没有相应修改，也没有声称 CI 绿。
- 未改任何门禁、shared/lib、其他轨道或根目录文件；未引入 npm 依赖。
- 无 origin、非支持的 GitHub 地址均采用纯文本，不提供 repoUrl 配置；未扩展到 GitLab、自建 Git 服务或其他 SSH 语法。
- 已存在但不可从 HEAD 到达的匹配 tag 不当作“无 tag”，describe 的真实错误保留。
- 无前一 tag 时 `<currentTag>^` 的范围语义沿用原实现，本卡只修正链接地址与降级展示。
- 初次 Prettier 检查发现新 Git 测试的格式差异，已格式化并重查通过。
- 独立核验脚本初次错误地固定取 CHANGELOG 第三行，被默认 header 的说明文字触发断言失败；已改为按 `## ` 查找标题，完整重跑通过。这是核验脚本错误，不是放宽产品测试断言。
- 报告因授权路径限制未写入根目录，位于 `shared/release/REPORT.md`，应由验收人排除在提交之外。
