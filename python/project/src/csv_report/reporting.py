"""Composable report formatting and one-pass, observable record consumption."""

from collections.abc import Iterable, Iterator, Sequence
from typing import Protocol

from .core import Group, Record, ReportRow, aggregate, format_money, render_table


class RecordObserver(Protocol):
    def on_record(self, record: Record) -> None: ...


class ReportTotals:  # L4-019-observer
    """Accumulate report footer values independently of category aggregation."""

    def __init__(self) -> None:
        self.rows = 0
        self.cents = 0

    def on_record(self, record: Record) -> None:
        self.rows += 1
        self.cents += record.cents


class ObservedRecords:  # L4-009-decorator
    """Preserve the iterable interface while notifying record subscribers."""

    def __init__(self, records: Iterable[Record], observers: Sequence[RecordObserver]) -> None:
        self.records = records
        self.observers = tuple(observers)

    def __iter__(self) -> Iterator[Record]:
        for record in self.records:
            for observer in self.observers:
                observer.on_record(record)
            yield record


class ReportPart(Protocol):
    def render(self) -> str: ...


class ReportText:
    def __init__(self, text: str) -> None:
        self.text = text

    def render(self) -> str:
        return self.text


class ReportSection:  # L4-008-composite
    """Render leaves and nested sections through the same component interface."""

    def __init__(self, parts: Sequence[ReportPart]) -> None:
        self.parts = tuple(parts)

    def render(self) -> str:
        return "\n".join(part.render() for part in self.parts)


class ReportBuilder:  # L4-004-builder
    """Require a table and footer before publishing a complete report tree."""

    def __init__(self) -> None:
        self.table: ReportText | None = None
        self.footer: ReportSection | None = None

    def with_table(self, table: str) -> "ReportBuilder":
        self.table = ReportText(table)
        return self

    def with_totals(self, totals: ReportTotals) -> "ReportBuilder":
        self.footer = ReportSection(
            (
                ReportText(f"rows: {totals.rows}"),
                ReportText(f"total: {format_money(totals.cents)}"),
            )
        )
        return self

    def build(self) -> ReportSection:
        if self.table is None or self.footer is None:
            raise ValueError("report requires a table and totals")
        return ReportSection((ReportText("CSV report"), self.table, self.footer))


class ReportFormat(Protocol):  # L4-021-strategy
    def format(self, groups: Sequence[Group], totals: ReportTotals) -> str: ...


class TableFormat:
    def format(self, groups: Sequence[Group], totals: ReportTotals) -> str:
        return render_table(ReportRow.headings, (ReportRow(group) for group in groups))


class FullReportFormat:
    def format(self, groups: Sequence[Group], totals: ReportTotals) -> str:
        table = TableFormat().format(groups, totals)
        return ReportBuilder().with_table(table).with_totals(totals).build().render()


class ReportingJob:
    def execute(self, records: Iterable[Record]) -> str:  # L4-022-template-method
        totals = ReportTotals()
        groups = aggregate(ObservedRecords(records, (totals,)))
        return self.create_formatter().format(groups, totals)

    def create_formatter(self) -> ReportFormat:  # L4-002-factory-method
        """Let the report variant create the formatter used by the template."""
        raise NotImplementedError("reporting job must provide a formatter")


class SummaryJob(ReportingJob):
    def create_formatter(self) -> ReportFormat:
        return TableFormat()


class FullReportJob(ReportingJob):
    def create_formatter(self) -> ReportFormat:
        return FullReportFormat()
