#!/usr/bin/env bash
# Usage: bash scripts/build-board.sh [result-log] [output-html]
# Requires Python 3 (standard library only). Relative arguments use the caller's cwd.
set -euo pipefail

if [ "$#" -gt 2 ]; then
  printf '用法: bash scripts/build-board.sh [结果日志] [输出路径]\n' >&2
  exit 2
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# 默认输出刻意不是 docs/进度看板.html：
# 那个文件是**仓库现状看板**（轨道清单 + 里程碑），由 scripts/build-repo-board.sh
# 从 docs/board-tracks.tsv + docs/ROADMAP.md 生成，生成结果入库、受 prettier 管辖；
# 本脚本产出的是**某一次执行的用例结果看板**，两者内容与生命周期都不同。
# 早先默认值写成 docs/进度看板.html，跑一次就会把文档覆盖成另一份东西，且 .gitignore
# 忽略的是 docs/progress.html —— 生成物反而会进工作树。现在两边对齐到 progress.html。
OUTPUT="${2:-$ROOT/docs/progress.html}"
export GOFLAGS="-buildvcs=false"
RESULTS=""
RUN_STATUS="provided"
if [ "$#" -eq 0 ]; then
  if RESULTS="$(TAG="${TAG:-latest}" bash "$ROOT/scripts/run-example.sh" all --all)"; then
    RUN_STATUS="0"
  else
    RUN_STATUS="$?"
    printf '警告: 用例 runner 返回非零状态，失败结果将如实展示。\n' >&2
  fi
fi

# Keep runner stdout in memory; fd 3 leaves stdin available for the Python program.
python3 - "$ROOT" "${1:-}" "$OUTPUT" "$RUN_STATUS" 3<<<"$RESULTS" <<'PY'
import os
import re
import sys
from datetime import datetime, timezone
from html import escape
from pathlib import Path


def build():
    root, log_path, output, run_status = sys.argv[1:]
    root = Path(root)
    if log_path:
        log = Path(log_path).read_text(encoding="utf-8")
    else:
        with os.fdopen(3, encoding="utf-8") as stream:
            log = stream.read()
    # 语言清单不在本脚本里写死：images/lang-images.tsv 是唯一真本。
    # 早先这里硬编码 6 门，仓库长到 9 轨之后它仍在按 6 门出看板，
    # 而 c / db / vue 的用例被静默漏掉 —— 看板看起来正常，数字是错的。
    tsv = root / "images" / "lang-images.tsv"
    if not tsv.is_file():
        raise ValueError("缺少语言清单: images/lang-images.tsv")
    languages = []
    for line in tsv.read_text(encoding="utf-8").splitlines():
        line = line.lstrip("\ufeff")
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        lang = line.split("\t")[0].strip()
        if lang and lang not in languages:
            languages.append(lang)
    if not languages:
        raise ValueError("images/lang-images.tsv 里没有语言行")
    levels = ("L0", "L1", "L2", "L3", "L4")
    results = {}
    # Include every failure status emitted by run-example.sh, not just FAIL.
    pattern = re.compile(
        r"^(" + "|".join(re.escape(lang) for lang in languages) + r")"
        r"/([A-Za-z0-9_.-]+)\s+"
        r"(PASS|FAIL|MISMATCH|NO-RUNNER|NO-EXPECTED|MISSING)\b"
    )
    for line in log.splitlines():
        line = re.sub(r"\x1b\[[0-9;]*m", "", line)
        match = pattern.match(line)
        if not match:
            continue
        lang, case, status = match.groups()
        key = (lang, case)
        status = "PASS" if status == "PASS" else "FAIL"
        if key in results and results[key] != status:
            raise ValueError("结果日志有冲突状态: " + lang + "/" + case)
        results[key] = status
    if not results:
        raise ValueError("结果日志没有可识别的用例结果，未生成看板")

    counts = {}
    coverage = {}
    known = set()
    for lang in languages:
        examples = root / lang / "examples"
        if not examples.is_dir():
            raise ValueError("缺少用例目录: " + lang + "/examples")
        counts[lang] = {level: dict(total=0, passed=0, failed=0, pending=0, unrun=0)
                        for level in (*levels, "other")}
        for case in sorted(examples.iterdir()):
            if not case.is_dir():
                continue
            key = (lang, case.name)
            known.add(key)
            match = re.match(r"^(L[0-4])-", case.name)
            level = match[1] if match else "other"
            row = counts[lang][level]
            row["total"] += 1
            status = results.get(key)
            row["passed"] += status == "PASS"
            row["failed"] += status == "FAIL"
            row["unrun"] += status is None
            readme = case / "README.md"
            row["pending"] += (
                readme.is_file()
                and "coverage: pending" in readme.read_text(encoding="utf-8")
            )
        text = (root / lang / "project" / "COVERAGE.md").read_text(encoding="utf-8")
        ids = []
        fenced = False
        for line in text.splitlines():
            if line.lstrip().startswith(("```", "~~~")):
                fenced = not fenced
            if fenced or not line.startswith("|"):
                continue
            case_id = line.split("|")[1].strip().strip("`")
            if re.fullmatch(r"[A-Za-z][A-Za-z0-9_.-]*", case_id):
                ids.append(case_id)
        coverage[lang] = ids
    if results.keys() - known:
        unknown = sorted(lang + "/" + case for lang, case in results.keys() - known)
        raise ValueError("结果日志包含不存在的用例: " + ", ".join(unknown))

    total = {field: sum(row[field] for groups in counts.values() for row in groups.values())
             for field in ("total", "passed", "failed", "pending", "unrun")}
    if total["unrun"]:
        print("警告: 结果日志未覆盖全部用例，未执行数将在看板单列展示。", file=sys.stderr)
    generated = datetime.now(timezone.utc).isoformat(timespec="seconds")
    sections = []
    for lang in languages:
        rows = []
        for level in (*levels, "other"):
            row = counts[lang][level]
            if level == "other" and not row["total"]:
                continue
            label = level if level != "other" else "其他（未分级）"
            cov_rows = sum(
                (case.startswith(level + "-") if level != "other"
                 else not re.match(r"^L[0-4]-", case))
                for case in coverage[lang]
            )
            percent = row["passed"] * 100 / row["total"] if row["total"] else 0
            rows.append(
                f'<tr data-lang="{lang}" data-level="{level}"><th scope="row">{label}</th>'
                f'<td class="total">{row["total"]}</td>'
                f'<td class="passed">{row["passed"]}</td>'
                f'<td class="failed">{row["failed"]}</td>'
                f'<td class="pending">{row["pending"]}</td>'
                f'<td class="unrun">{row["unrun"]}</td><td class="coverage">{cov_rows}</td>'
                f'<td><progress max="100" value="{percent:.1f}" aria-label="{lang} {label} PASS 完成度">'
                f'{percent:.1f}%</progress> {percent:.1f}%</td></tr>'
            )
        sections.append(
            f'<section><h2>{lang} <small>COVERAGE 表数据行：{len(coverage[lang])}</small></h2>'
            '<div class="table-scroll"><table><thead><tr><th scope="col">级别</th>'
            '<th scope="col">总数</th><th scope="col">PASS</th><th scope="col">FAIL</th>'
            '<th scope="col">pending</th><th scope="col">未执行</th>'
            '<th scope="col">COVERAGE 行数</th><th scope="col">执行完成度</th>'
            '</tr></thead><tbody>' + "".join(rows) + '</tbody></table></div></section>'
        )
    source = "提供的结果日志" if log_path else "run-example.sh all --all"
    runner = "" if run_status == "provided" else f"；runner 退出状态：{escape(run_status)}"
    document = '''<!doctype html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="color-scheme" content="light dark">
<title>进度看板 R-W-05</title>
<style>
:root { color-scheme: light; --bg: #f4f6fa; --surface: #fff; --text: #17213a;
  --muted: #536078; --line: #d9dfeb; --pass: #14653a; --fail: #b32323; --pending: #855300; }
:root[data-theme="dark"] { color-scheme: dark; --bg: #101622; --surface: #1a2333;
  --text: #e8edf7; --muted: #b5c1d5; --line: #35425a; --pass: #80dfa4;
  --fail: #ff9a9a; --pending: #f5cf7c; }
@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) { color-scheme: dark; --bg: #101622; --surface: #1a2333;
    --text: #e8edf7; --muted: #b5c1d5; --line: #35425a; --pass: #80dfa4;
    --fail: #ff9a9a; --pending: #f5cf7c; }
}
* { box-sizing: border-box; }
body { margin: 0; background: var(--bg); color: var(--text);
  font-family: system-ui, sans-serif; line-height: 1.6; }
header, main, footer { max-width: 1200px; margin: auto; padding: 1rem; }
header { display: flex; align-items: center; justify-content: space-between; gap: 1rem; }
h1 { font-size: 1.6rem; margin: 0; }
h2 { font-size: 1.2rem; margin-top: 0; }
small, footer, .note { color: var(--muted); }
small { font-weight: normal; font-size: .85rem; }
button { background: var(--surface); color: var(--text); border: 1px solid var(--line);
  padding: .6rem 1rem; border-radius: .5rem; cursor: pointer; }
button:focus-visible { outline: 3px solid var(--pending); outline-offset: 3px; }
section, .summary { background: var(--surface); border: 1px solid var(--line);
  border-radius: .7rem; padding: 1rem; margin-bottom: 1rem; }
.summary { font-weight: bold; }
.table-scroll { overflow-x: auto; }
table { width: 100%; border-collapse: collapse; white-space: nowrap; }
th, td { padding: .6rem; text-align: right; border-bottom: 1px solid var(--line); }
th:first-child { text-align: left; }
.passed { color: var(--pass); } .failed { color: var(--fail); }
.pending { color: var(--pending); }
progress { width: 6rem; height: .7rem; accent-color: var(--pass); }
@media (max-width: 600px) { header { align-items: flex-start; } h1 { font-size: 1.2rem; } }
</style>
</head>
<body>
<header><h1>进度看板 R-W-05</h1><button id="theme-toggle" type="button"
aria-pressed="false">切换主题</button></header>
<main>
'''
    document += (
        f'<p class="summary" id="overall">总用例数：{total["total"]} · 总 PASS：{total["passed"]}'
        f' · 总 FAIL：{total["failed"]} · 总 pending：{total["pending"]}'
        f' · 未执行：{total["unrun"]} · 生成时间：<time datetime="{generated}">{generated}</time></p>\n'
        f'<p class="note">结果来源：{source}{runner}。'
        '执行完成度 = PASS / 用例总数；pending 是项目覆盖欠债，与 PASS/FAIL 独立，'
        '可以同时为 PASS 和 pending。未执行不计为 PASS 或 FAIL。'
        'COVERAGE 行数不含表头、分隔行和代码块，也不代表代码引用校验已通过。'
        '总体包含 L0、L4 等非 L1/L2/L3 用例。</p>\n'
    )
    document += "\n".join(sections)
    document += '''
<p class="note" id="theme-status" role="status"></p>
</main>
<footer>自包含 HTML · 零 CDN · 系统主题自动适配，手动选择保存在当前浏览器。
重新生成：bash scripts/build-board.sh [结果日志] [输出路径]（需要 Python 3，默认写 docs/progress.html）。
不提供日志时执行全部用例，默认 TAG=latest；中间日志仅保留在内存。<br>
覆盖范围仅限 <code>images/lang-images.tsv</code> 里的语言轨道；数据库轨道走独立 Compose runner（<code>db/scripts/run-all.sh</code>），不在本看板内。</footer>
<script>
(() => {
  const root = document.documentElement;
  const button = document.getElementById('theme-toggle');
  const status = document.getElementById('theme-status');
  const system = window.matchMedia('(prefers-color-scheme: dark)');
  const key = 'devbox-board-theme';
  const isDark = () => root.dataset.theme ? root.dataset.theme === 'dark' : system.matches;
  const update = () => {
    button.setAttribute('aria-pressed', String(isDark()));
    button.textContent = isDark() ? '切换浅色' : '切换深色';
  };
  try {
    const saved = localStorage.getItem(key);
    if (saved === 'light' || saved === 'dark') root.dataset.theme = saved;
  } catch (error) {
    status.textContent = '浏览器存储不可用：主题选择仅在本次页面有效。';
    console.warn('无法读取主题选择', error);
  }
  button.addEventListener('click', () => {
    root.dataset.theme = isDark() ? 'light' : 'dark';
    update();
    try {
      localStorage.setItem(key, root.dataset.theme);
    } catch (error) {
      status.textContent = '无法保存主题选择：主题选择仅在本次页面有效。';
      console.warn('无法保存主题选择', error);
    }
  });
  system.addEventListener('change', update);
  update();
})();
</script>
</body>
</html>
'''
    target = Path(output)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(document, encoding="utf-8")
    print("进度看板已生成。")


try:
    build()
except (OSError, UnicodeError, ValueError) as error:
    print("构建进度看板失败: " + str(error), file=sys.stderr)
    sys.exit(1)
PY
