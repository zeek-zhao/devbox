"""Design-pattern contracts exercised by the real summary/report dispatch."""

from unittest.mock import patch

import pytest

from csv_report.cli import execute
from csv_report.core import DataError, Group, Record, ReportRow, render_table
from csv_report.reporting import (
    FullReportFormat,
    FullReportJob,
    ObservedRecords,
    ReportBuilder,
    ReportingJob,
    ReportSection,
    ReportText,
    ReportTotals,
    SummaryJob,
    TableFormat,
)


def test_adapter_preserves_domain_group():
    group = Group("food", 2, 30)
    row = ReportRow(group)
    assert row.group is group
    assert row.cells() == ("food", "2", "0.30")
    assert render_table(ReportRow.headings, [row]).endswith("food     | 2     | 0.30 ")
    assert group == Group("food", 2, 30)


def test_decorator_is_lazy_stackable_and_notifies_each_subscriber():
    records = iter([Record("2026-01-01", "food", 10), Record("2026-01-02", "food", 20)])
    inner = ReportTotals()
    outer = ReportTotals()
    second = ReportTotals()
    decorated = ObservedRecords(ObservedRecords(records, (inner,)), (outer, second))
    assert (inner.rows, outer.rows, second.rows) == (0, 0, 0)
    stream = iter(decorated)
    assert next(stream).cents == 10
    assert [(o.rows, o.cents) for o in (inner, outer, second)] == [(1, 10)] * 3
    assert [record.cents for record in stream] == [20]
    assert [(o.rows, o.cents) for o in (inner, outer, second)] == [(2, 30)] * 3
    assert list(decorated) == []
    assert inner.rows == outer.rows == second.rows == 2


def test_observer_failure_propagates_before_record_is_yielded():
    class RejectRecord:
        def on_record(self, record):
            raise DataError("subscriber rejected record")

    stream = iter(ObservedRecords([Record("2026-01-01", "food", 10)], (RejectRecord(),)))
    with pytest.raises(DataError, match="subscriber rejected record"):
        next(stream)


def test_composite_supports_nested_sections_and_empty_sections():
    section = ReportSection(
        (ReportText("header"), ReportSection((ReportText("rows: 2"), ReportText("total: 0.30"))))
    )
    assert section.render() == "header\nrows: 2\ntotal: 0.30"
    assert ReportSection(()).render() == ""
    assert section.render() == section.render()


def test_builder_requires_complete_parts_and_snapshots_totals():
    totals = ReportTotals()
    builder = ReportBuilder()
    with pytest.raises(ValueError, match="requires a table and totals"):
        builder.build()
    builder.with_table("table")
    with pytest.raises(ValueError, match="requires a table and totals"):
        builder.build()
    report = builder.with_totals(totals).build()
    totals.on_record(Record("2026-01-01", "food", 10))
    builder.with_table("replacement").with_totals(totals)
    assert report.render() == "CSV report\ntable\nrows: 0\ntotal: 0.00"
    assert builder.build().render() == "CSV report\nreplacement\nrows: 1\ntotal: 0.10"
    with pytest.raises(ValueError, match="requires a table and totals"):
        ReportBuilder().with_totals(totals).build()


def test_factories_produce_interchangeable_format_strategies():
    with pytest.raises(NotImplementedError, match="must provide a formatter"):
        ReportingJob().create_formatter()
    totals = ReportTotals()
    totals.on_record(Record("2026-01-01", "food", 30))
    groups = [Group("food", 1, 30)]
    summary = SummaryJob().create_formatter()
    full = FullReportJob().create_formatter()
    assert isinstance(summary, TableFormat)
    assert isinstance(full, FullReportFormat)
    table = summary.format(groups, totals)
    assert full.format(groups, totals) == f"CSV report\n{table}\nrows: 1\ntotal: 0.30"


def test_template_consumes_once_before_calling_factory():
    events = []

    def records():
        events.append("read")
        yield Record("2026-01-01", "food", 10)
        yield Record("2026-01-01", "food", 10)

    class InspectFormat:
        def format(self, groups, totals):
            events.append("format")
            assert groups == [Group("food", 2, 20)]
            assert (totals.rows, totals.cents) == (2, 20)
            return "inspected"

    class InspectJob(ReportingJob):
        def create_formatter(self):
            events.append("factory")
            return InspectFormat()

    assert InspectJob().execute(records()) == "inspected"
    assert events == ["read", "factory", "format"]


@pytest.mark.parametrize("command,job", [("summary", SummaryJob), ("report", FullReportJob)])
def test_cli_reaches_factory_and_template(tmp_path, command, job):
    source = tmp_path / "input.csv"
    source.write_text(
        "date,category,amount\n2026-01-01, Food ,0.10\n2026-01-01,food,0.10\n",
        encoding="utf-8",
    )
    with patch.object(job, "create_formatter", autospec=True) as factory:
        factory.return_value = TableFormat() if command == "summary" else FullReportFormat()
        result = execute(command, source)
        factory.assert_called_once()
    assert "food     | 2     | 0.20" in result
    if command == "report":
        assert result.endswith("rows: 2\ntotal: 0.20")


def test_template_rejects_partial_input_and_keeps_runs_independent():
    def broken():
        yield Record("2026-01-01", "food", 10)
        raise DataError("invalid next row")

    job = FullReportJob()
    with patch.object(job, "create_formatter") as factory:
        with pytest.raises(DataError, match="invalid next row"):
            job.execute(broken())
        factory.assert_not_called()
    assert job.execute([]).endswith("rows: 0\ntotal: 0.00")
    assert job.execute([Record("2026-01-01", "food", 10)]).endswith("rows: 1\ntotal: 0.10")
    assert job.execute([]).endswith("rows: 0\ntotal: 0.00")
