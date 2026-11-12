#!/usr/bin/env bash
# Advisory-only README structure coverage for standard examples.
# T-* troubleshooting drills are deliberately excluded from this denominator.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec python3 - "$ROOT" <<'PY'
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
tracks = ("c", "cpp", "go", "java", "python", "rust", "shell", "vue", "db")
sections = ("考点", "易错点", "复现", "延伸")

# Exact normalized H2 headings only: body text and partial-word matches never count.
# Legacy aliases are intentionally narrow. 契约/判据 count as reproduction only
# when their section contains an executable command block, not deployment policy.
aliases = {
    "考点": {"考点", "考点说明"},
    "易错点": {"易错点"},
    "复现": {"复现", "复现命令", "运行", "怎么跑"},
    "延伸": {"延伸", "延伸阅读"},
}
operational_aliases = {"契约", "判据", "判据（验收按这一条核对）"}
runner_command_pattern = re.compile(r"(?im)^\s*TAG=[^\s]+\s+(?:bash\s+)?scripts/run-example\.sh\s+[\w-]+\s+[A-Z0-9][A-Z0-9-]*\s*(?:#.*)?$")
h2_pattern = re.compile(r"^ {0,3}##[ \t]+(.+?)\s*#*\s*$")


def normalize(title: str) -> str:
    title = re.sub(r"[`*_]", "", title)
    title = re.sub(r"\s+", " ", title).strip()
    return title.rstrip("：:").strip()


def read_sections(path: Path):
    found = []
    current_title = None
    body = []
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeError) as exc:
        return None, str(exc)
    fence_char = None
    fence_size = 0
    for line in lines:
        stripped = line.lstrip()
        fence = re.match(r"^(`{3,}|~{3,})", stripped)
        if fence:
            marker = fence.group(1)
            if fence_char is None:
                fence_char, fence_size = marker[0], len(marker)
            elif marker[0] == fence_char and len(marker) >= fence_size:
                fence_char, fence_size = None, 0
            continue
        if fence_char is not None:
            continue
        match = h2_pattern.match(line)
        if match:
            if current_title is not None:
                found.append((current_title, "\n".join(body)))
            current_title = normalize(match.group(1))
            body = []
        elif current_title is not None:
            body.append(line)
    if current_title is not None:
        found.append((current_title, "\n".join(body)))
    return found, None


def has_section(parsed, category):
    accepted = aliases[category]
    for title, body in parsed:
        if title in accepted:
            return True
        if category == "复现" and title in operational_aliases and runner_command_pattern.search(body):
            return True
    return False

print("README 结构覆盖（advisory；仅统计带 run.sh 的普通 examples，排除 T-* 演练）")
print("标题规则：精确规范化 H2；契约/判据仅在正文含可执行命令时映射为复现。")
print("| 轨道 | 普通用例 | 考点 | 易错点 | 复现 | 延伸 |")
print("|---|---:|---:|---:|---:|---:|")
all_counts = {section: [0, 0] for section in sections}
all_total = 0
for track in tracks:
    track_dir = root / track / "examples"
    try:
        dirs = sorted(p for p in track_dir.iterdir() if p.is_dir() and not p.name.startswith("T-") and (p / "run.sh").is_file()) if track_dir.is_dir() else []
    except OSError as exc:
        print(f"WARN {track}: examples directory unreadable — {exc}")
        dirs = []
    counts = {section: 0 for section in sections}
    unreadable = 0
    missing_readme = 0
    for example in dirs:
        readme = example / "README.md"
        if not readme.is_file():
            missing_readme += 1
            continue
        parsed, error = read_sections(readme)
        if error:
            unreadable += 1
            continue
        for section in sections:
            if has_section(parsed, section):
                counts[section] += 1
    denominator = len(dirs)
    all_total += denominator
    cells = []
    for section in sections:
        all_counts[section][0] += counts[section]
        all_counts[section][1] += denominator
        pct = (100.0 * counts[section] / denominator) if denominator else 0.0
        cells.append(f"{counts[section]}/{denominator} ({pct:.1f}%)")
    print(f"| {track} | {denominator} | " + " | ".join(cells) + " |")
    missing = [f"{s} {denominator - counts[s]}" for s in sections if denominator - counts[s] > 0]
    if missing:
        print(f"WARN {track}: sections missing — " + ", ".join(missing))
    if missing_readme or unreadable:
        print(f"WARN {track}: README missing={missing_readme}, unreadable={unreadable}")

cells = []
for section in sections:
    hit, denom = all_counts[section]
    pct = (100.0 * hit / denom) if denom else 0.0
    cells.append(f"{hit}/{denom} ({pct:.1f}%)")
print(f"| **合计** | **{all_total}** | " + " | ".join(cells) + " |")
print("WARN only: missing sections do not fail this script or CI.")
PY
