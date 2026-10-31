"""Normal, invalid-input and language-contract checks against the CSV pipeline."""

import copy
import importlib.resources
import json
import logging
import subprocess
import sys
from collections import deque
from dataclasses import FrozenInstanceError, dataclass, field
from enum import Enum
from functools import wraps
from pathlib import Path
from unittest.mock import patch

import pytest

from csv_report.cli import SAMPLE, AtomicOutput, Workspace, execute, run, self_check
from csv_report.core import (
    Category,
    DataError,
    Group,
    Record,
    ReportRow,
    aggregate,
    format_money,
    parse_money,
    read_records,
    render_table,
    unique_records,
)

PROJECT = Path(__file__).resolve().parents[1]


@pytest.fixture  # L2-002-pytest-basics
def source(tmp_path):
    resource = importlib.resources.files("tests.fixtures").joinpath(  # L2-012-package-resources
        "input.csv"
    )
    path = tmp_path / "input with spaces.csv"
    path.write_text(resource.read_text(encoding="utf-8"), encoding="utf-8")
    assert path.read_text(encoding="utf-8") == SAMPLE
    return path


def test_pipeline(source, tmp_path):
    output = tmp_path / "clean.csv"
    assert run(["clean", str(source), str(output)]) == "clean: 3 rows"
    assert list(read_records(output)) == [
        Record("2026-01-01", "food", 1250),
        Record("2026-01-02", "books", 2000),
        Record("2026-01-03", "food", 10),
    ]
    expected = (
        "category | count | total\n"
        "---------+-------+------\n"
        "books    | 1     | 20.00\n"
        "food     | 2     | 12.60"
    )
    assert run(["summary", str(output)]) == expected
    assert (
        run(["report", str(output)]) == f"CSV report\n{expected}\nrows: 3\ntotal: 32.60"
    )
    assert run(["clean", str(output), str(output)]) == "clean: 3 rows"


@pytest.mark.parametrize(
    "amount,cents",
    [("0", 0), ("0.1", 10), ("12.50", 1250), ("999999999999.99", 99999999999999)],
)
def test_exact_money(amount, cents):
    assert parse_money(amount) == cents
    assert parse_money(format_money(cents)) == cents
    assert parse_money("0.10") + parse_money("0.20") == 30


@pytest.mark.parametrize(
    "amount", ["", "-1", "NaN", "1e3", "1.234", "1.", ".1", "１.00"]
)
def test_bad_money(amount):
    with pytest.raises(DataError):
        parse_money(amount)


@pytest.mark.parametrize(
    "content",
    [
        "",
        "wrong,category,amount\n",
        "date,category,amount\n2026-02-30,x,1\n",
        "date,category,amount\n20260101,x,1\n",
        "date,category,amount\n2026-01-01, ,1\n",
        "date,category,amount\n2026-01-01,x,no\n",
        "date,category,amount\nx,y\n",
        'date,category,amount\n"unterminated\n',
    ],
)
def test_bad_csv_preserves_output(tmp_path, content):
    source = tmp_path / "bad.csv"
    source.write_text(content, encoding="utf-8")
    output = tmp_path / "clean.csv"
    output.write_text("previous result", encoding="utf-8")
    with pytest.raises(DataError):
        execute("clean", source, output)
    assert output.read_text(encoding="utf-8") == "previous result"
    assert not output.with_name("clean.csv.tmp").exists()


def test_bom_quotes_blank_and_empty(tmp_path):
    source = tmp_path / "input.csv"
    source.write_text(
        '\ufeffdate,category,amount\n\n,,\n2026-01-01," Café, BAR ",0.20\n',
        encoding="utf-8",
    )
    records = list(read_records(source))
    assert records == [Record("2026-01-01", "café, bar", 20)]
    output = tmp_path / "output.csv"
    execute("clean", source, output)
    assert list(read_records(output)) == records
    source.write_text("date,category,amount\n", encoding="utf-8")
    assert execute("report", source).endswith("rows: 0\ntotal: 0.00")


def test_generator_is_lazy_and_chained(tmp_path):
    path = tmp_path / "missing.csv"
    rows = read_records(path)
    with pytest.raises(FileNotFoundError):
        next(rows)
    path.write_text("date,category,amount\n2026-01-01,x,no\n", encoding="utf-8")
    with pytest.raises(DataError) as error:
        next(read_records(path))
    assert isinstance(error.value.__cause__, ValueError)


def test_workspace_cleanup_and_collision(tmp_path):
    path = tmp_path / "workspace"
    with pytest.raises(RuntimeError), Workspace(path) as owned:
        (owned / "input.csv").write_text("data", encoding="utf-8")
        raise RuntimeError("abort")
    assert not path.exists()
    path.mkdir()
    with pytest.raises(FileExistsError), Workspace(path):
        pytest.fail("must not reuse somebody else's directory")
    assert path.is_dir()


def test_atomic_collision(tmp_path):
    output = tmp_path / "output.csv"
    reserved = tmp_path / "output.csv.tmp"
    reserved.write_text("owned by another writer", encoding="utf-8")
    with pytest.raises(FileExistsError), AtomicOutput(output):
        pytest.fail("must not overwrite reservation")
    assert reserved.read_text(encoding="utf-8") == "owned by another writer"


def test_self_check_is_repeatable():
    assert run(["--self-check"]) == self_check()
    assert self_check().endswith("rows: 3\ntotal: 32.60")


@pytest.mark.parametrize(
    "argv", [[], ["clean"], ["summary"], ["--self-check", "report", "x"]]
)
def test_cli_usage_errors(argv, capsys):
    with pytest.raises(SystemExit) as error:
        run(argv)
    assert error.value.code == 2
    assert "error:" in capsys.readouterr().err


def test_cli_missing_and_help(tmp_path, capsys):
    with pytest.raises(SystemExit) as error:
        run(["summary", str(tmp_path / "missing.csv")])
    assert error.value.code == 2
    assert "error:" in capsys.readouterr().err
    with pytest.raises(SystemExit) as help_result:
        run(["--help"])
    assert help_result.value.code == 0
    assert "clean,summary,report" in capsys.readouterr().out


def test_real_process_and_import(source):
    result = subprocess.run(  # L2-008-subprocess
        [sys.executable, str(PROJECT / "src/main.py"), "summary", str(source)],
        capture_output=True,
        text=True,
        check=True,
        cwd=source.parent,
    )
    assert "food     | 3     | 25.10" in result.stdout
    imported = subprocess.run(
        [sys.executable, "-c", "import main; import csv_report"],
        capture_output=True,
        text=True,
        check=True,
        cwd=source.parent,
    )
    assert imported.stdout == imported.stderr == ""
    with pytest.raises(subprocess.CalledProcessError):
        subprocess.run(
            [sys.executable, str(PROJECT / "src/main.py"), "invalid"],
            capture_output=True,
            text=True,
            check=True,
        )


def test_mock_file_boundary(tmp_path):
    with patch(  # L2-011-mock-boundaries
        "csv_report.cli.read_records",
        return_value=iter([Record("2026-01-01", "x", 100)]),
    ) as read:
        assert execute("report", tmp_path / "external.csv").endswith("total: 1.00")
        read.assert_called_once_with(tmp_path / "external.csv")


def test_diagnostic_logging(source, caplog):
    logger = logging.getLogger("csv-report.validation")  # L2-006-logging
    with caplog.at_level(logging.WARNING, logger=logger.name):
        logger.info("begin validation")
        try:
            execute("unknown", source)
        except DataError as exc:
            logger.warning("rejected command: %s", exc)
    assert [
        (entry.name, entry.levelname, entry.message) for entry in caplog.records
    ] == [
        (
            "csv-report.validation",
            "WARNING",
            "rejected command: unknown command: unknown",
        )
    ]


def test_record_binding_and_copies(source):
    original = list(read_records(source))
    alias = original
    original = original[:1]  # L1-001-name-object
    assert len(alias) == 4 and len(original) == 1
    equal = list(alias)
    assert equal == alias and equal is not alias  # L1-002-mutability-identity
    batches = [alias[:2], alias[2:]]
    shallow = batches[:]
    deep = copy.deepcopy(batches)  # L1-003-slice-copy
    shallow[0].append(Record("2026-01-04", "x", 1))
    assert len(batches[0]) == 3 and len(deep[0]) == 2
    keys = set(alias)  # L1-004-builtin-containers
    assert len(keys) == 3
    assert alias[-1] == Record("2026-01-03", "food", 10)
    assert alias[::-1][0] == alias[-1] and alias[99:] == []
    assert list(unique_records(alias)) == list(unique_records(alias))


def test_scoped_transformations(source):
    calls = 0

    def count(record):
        """Count consumed CSV records without changing their values."""
        nonlocal calls  # L1-009-scope-nonlocal
        calls += 1
        return record

    def traced(label):
        def decorate(function):
            @wraps(function)  # L1-011-decorators-wraps
            def wrapper(record):
                return label, function(record)

            return wrapper

        return decorate

    wrapped = traced("csv")(count)
    lazy = (wrapped(row) for row in read_records(source))
    assert calls == 0
    assert next(lazy)[0] == "csv" and calls == 1
    assert len(list(lazy)) == 3 and calls == 4
    assert wrapped.__name__ == "count"
    assert wrapped.__doc__ == count.__doc__
    selectors = [
        lambda row, column=column: row[column]
        for column in range(3)  # L1-010-closure-late-binding
    ]
    row = Record("2026-01-01", "x", 10)
    assert [select(row) for select in selectors] == ["2026-01-01", "x", 10]
    late = [lambda: column for column in range(3)]  # noqa: B023 - test the late-binding pitfall
    assert [function() for function in late] == [2, 2, 2]


def test_iterator_exhaustion(source):
    class RecordQueue:
        def __init__(self, records):
            self.pending = deque(records)

        def __iter__(self):
            return self

        def __next__(self):  # L1-013-iterator-protocol
            if not self.pending:
                raise StopIteration
            return self.pending.popleft()

    records = list(read_records(source))
    queue = RecordQueue(records)
    assert iter(queue) is queue
    assert aggregate(queue) == aggregate(records)
    with pytest.raises(StopIteration):
        next(queue)


def test_class_contracts():
    first, second = ReportRow(Group("x", 1, 10)), ReportRow(Group("y", 2, 20))
    assert first.headings is second.headings
    assert first.group != second.group
    with pytest.raises(AttributeError):
        first.extra = "not allowed"
    category = Category(" Food ")
    assert category.value == "food"
    category.value = "BOOKS"
    assert category.value == "books"
    with pytest.raises(DataError):
        category.value = ""
    assert category.value == "books"
    assert Record("2026-01-01", "x", 10) == Record("2026-01-01", "x", 10)
    assert len({Record("2026-01-01", "x", 10), Record("2026-01-01", "x", 10)}) == 1

    class AnnotatedRow(ReportRow):
        __slots__ = ("note",)

        def __init__(self, group, note):
            super().__init__(group)  # L1-021-inheritance-super
            self.note = note

        def cells(self):
            return (*super().cells(), self.note)

    row = AnnotatedRow(Group("x", 1, 10), "verified")
    assert render_table((*row.headings, "note"), [row]).endswith(
        "x        | 1     | 0.10  | verified"
    )


@dataclass(frozen=True)  # L1-022-dataclass
class ExpectedBatch:
    records: list[Record] = field(default_factory=list)


def test_dataclass_expected_batch(source):
    first, second = ExpectedBatch(), ExpectedBatch()
    assert first == second and first.records is not second.records
    first.records.extend(unique_records(read_records(source)))
    assert len(first.records) == 3 and not second.records
    with pytest.raises(FrozenInstanceError):
        first.records = []


class Command(Enum):  # L1-029-enum-states
    CLEAN = "clean"
    SUMMARY = "summary"
    REPORT = "report"


def test_enum_dispatch(source, tmp_path):
    assert Command("clean") is Command.CLEAN
    assert Command.CLEAN != "clean" and Command.CLEAN.name == "CLEAN"
    output = tmp_path / "out.csv"
    assert execute(Command.CLEAN.value, source, output) == "clean: 3 rows"
    assert execute(Command.REPORT.value, output).startswith("CSV report")


def test_unicode_width_and_structural_table():
    category = "咖啡"  # L1-027-unicode-strings
    assert len(category) == 2 and len(category.encode("utf-8")) == 6
    text = render_table(ReportRow.headings, [ReportRow(Group(category, 1, 20))])
    assert text.splitlines()[-1] == "咖啡       | 1     | 0.20 "
    long = ReportRow(Group("a category longer than any header", 1000, 99999999))
    lines = render_table(ReportRow.headings, [long]).splitlines()
    assert len({len(line) for line in lines}) == 1
    with pytest.raises(ValueError):
        render_table([], [])
    with pytest.raises(ValueError):
        render_table(["one"], [long])
    with pytest.raises(TypeError):
        format_money(True)
    with pytest.raises(DataError):
        format_money(-1)


def test_json_summary_roundtrip(source):
    groups = aggregate(unique_records(read_records(source)))
    payload = [group._asdict() for group in groups]
    encoded = json.dumps(payload, sort_keys=True, separators=(",", ":"))  # L2-009-json
    assert json.loads(encoded) == payload
    assert (
        encoded
        == '[{"category":"books","cents":2000,"row_count":1},{"category":"food","cents":1260,"row_count":2}]'
    )


def test_cache_contract():
    parse_money.cache_clear()
    assert parse_money("0.10") == parse_money("0.10") == 10
    assert parse_money.cache_info().hits == 1
    assert parse_money.cache_info().misses == 1
    with pytest.raises(TypeError):
        parse_money(["0.10"])
    parse_money.cache_clear()


def test_signature_and_stable_sort(source):
    records = list(read_records(source))
    seen = {records[0]}
    assert list(unique_records(records, seen=seen)) == [records[1], records[-1]]
    with pytest.raises(TypeError):
        unique_records(records=records)
    with pytest.raises(TypeError):
        unique_records(records, set())
    tied = [Record("2026-01-01", "a", 10), Record("2026-01-01", "A", 20)]
    before = tied[:]
    assert [group.category for group in aggregate(tied)] == ["a", "A"]
    assert tied == before


def test_internal_table_invariant():
    # Simulate a formatting regression; external validation remains ValueError.
    with (
        patch("csv_report.core.zip", return_value=[], create=True),
        pytest.raises(AssertionError),
    ):
        render_table(ReportRow.headings, [ReportRow(Group("x", 1, 10))])


def test_hello_environment():
    assert sys.version_info[:2] == (3, 12)  # hello
    assert sum(range(5)) == 10
    assert (3 * 3 + 4 * 4) ** 0.5 == 5
    assert ExpectedBatch() == ExpectedBatch()
