"""Development-only portability, concurrency, profiling and checker negatives."""

import asyncio
import cProfile
import ctypes
import multiprocessing
import pstats
import struct
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import pytest

from csv_report.core import Category, Record, aggregate, parse_money

PROJECT = Path(__file__).resolve().parents[1]


def normalize_task(text):
    return Category(text).value


def cpu_task(amount):
    # Fixed operation count, deliberately no timing-based GIL claims.
    return sum(parse_money(amount) for _ in range(1000))


def test_multiprocessing_normalization():
    data = [" Food ", "BOOKS", " café "]
    with multiprocessing.get_context("spawn").Pool(  # L3-002-multiprocessing-pool
        2
    ) as pool:
        assert pool.map(normalize_task, data) == ["food", "books", "café"]


def test_gil_work_equivalence():
    amounts = ["0.10", "0.20", "1.00"]
    serial = list(map(cpu_task, amounts))
    with ThreadPoolExecutor(max_workers=2) as threads:  # L3-006-gil-cpu-work
        threaded = list(threads.map(cpu_task, amounts))
    with multiprocessing.get_context("spawn").Pool(2) as pool:
        parallel = pool.map(cpu_task, amounts)
    assert serial == threaded == parallel == [10000, 20000, 100000]
    assert len(amounts) * 1000 == 3000
    # CPython's standard GIL serializes Python threads; processes have separate GILs.


def test_async_batch_and_cancellation():
    async def scenario():
        async def normalize(text):
            return normalize_task(text)

        results = await asyncio.gather(  # L3-001-asyncio-timeout
            *(normalize(text) for text in [" Food ", "BOOKS"])
        )
        assert sorted(results) == ["books", "food"]
        entered = asyncio.Event()
        cleaned = asyncio.Event()

        async def blocked():
            try:
                entered.set()
                await asyncio.Future()
            finally:
                cleaned.set()

        task = asyncio.create_task(blocked())
        await entered.wait()
        with pytest.raises(TimeoutError):
            await asyncio.wait_for(task, timeout=0)
        assert task.cancelled() and cleaned.is_set()

    asyncio.run(scenario())


def test_profile_aggregation():
    records = [Record("2026-01-01", "food", 10)] * 10
    profiler = cProfile.Profile()  # L3-003-cprofile
    groups = profiler.runcall(aggregate, records)
    assert groups[0].cents == 100
    stats = pstats.Stats(profiler)
    calls = sorted(
        (key[2], entry[1])
        for key, entry in stats.stats.items()
        if key[2] == "aggregate"
    )
    assert calls == [("aggregate", 1)]


def test_binary_summary_encoding():
    group = aggregate([Record("2026-01-01", "food", 1250)])[0]
    encoded = struct.pack(">Iq", group.row_count, group.cents)  # L3-004-struct-binary
    assert encoded.hex() == "0000000100000000000004e2"
    assert struct.calcsize(">Iq") == 12
    assert struct.unpack(">Iq", encoded) == (1, 1250)


def test_libc_utf8_boundary():
    libc = ctypes.CDLL("libc.so.6")  # L3-005-ctypes-libc
    libc.strlen.argtypes = [ctypes.c_char_p]
    libc.strlen.restype = ctypes.c_size_t
    text = normalize_task(" CAFÉ ").encode("utf-8")
    assert libc.strlen(text) == len(text) == 5


@pytest.mark.parametrize(
    "tool,content",
    [
        ("ruff", "import pathlib\n"),
        (
            "mypy",
            'from csv_report.core import format_money\nformat_money("not cents")\n',
        ),
    ],
)
def test_checker_rejects_bad_code(tmp_path, tool, content):
    bad = tmp_path / "bad.py"
    bad.write_text(content, encoding="utf-8")
    command = (
        [tool, "check", str(bad)]
        if tool == "ruff"
        else [tool, "--strict", str(PROJECT / "src"), str(bad)]
    )
    result = subprocess.run(
        command, check=False, capture_output=True, text=True, cwd=PROJECT
    )
    assert result.returncode == 1
    assert ("F401" if tool == "ruff" else "arg-type") in result.stdout


def test_runtime_import_allowlist():
    import ast

    allowed = {
        "csv",
        "argparse",
        "pathlib",
        "typing",
        "re",
        "collections",
        "itertools",
        "functools",
        "datetime",
        "textwrap",
        "csv_report",
    }
    for path in (PROJECT / "src").rglob("*.py"):
        for node in ast.walk(ast.parse(path.read_text(encoding="utf-8"))):
            if isinstance(node, ast.Import):
                assert all(alias.name.split(".")[0] in allowed for alias in node.names)
            elif isinstance(node, ast.ImportFrom) and node.level == 0:
                assert node.module.split(".")[0] in allowed
    result = subprocess.run(
        [sys.executable, "-c", "import csv_report.core, csv_report.cli"],
        capture_output=True,
        text=True,
        check=True,
    )
    assert result.stdout == result.stderr == ""
