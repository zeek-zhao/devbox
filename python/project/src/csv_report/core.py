"""Streaming CSV validation, exact integer money and stable text tables."""

import csv
import re
from collections import Counter, defaultdict
from collections.abc import Iterable, Iterator, Sequence
from datetime import date
from functools import lru_cache
from pathlib import Path
from typing import NamedTuple, Protocol


class DataError(ValueError):
    """Invalid external CSV data."""


class Record(NamedTuple):
    day: str
    category: str
    cents: int


class Group(NamedTuple):
    category: str
    row_count: int
    cents: int


class TableRow(Protocol):  # L2-003-typing-protocols
    def cells(self) -> Sequence[str]: ...


class ReportRow:  # L4-006-adapter
    __slots__ = ("group",)  # L1-018-slots
    headings = ("category", "count", "total")  # L1-017-class-attributes

    def __init__(self, group: Group) -> None:
        self.group = group

    def cells(self) -> Sequence[str]:
        return (
            self.group.category,
            str(self.group.row_count),
            format_money(self.group.cents),
        )


class Category:
    __slots__ = ("_value",)

    def __init__(self, value: str) -> None:
        self.value = value

    @property
    def value(self) -> str:
        return self._value

    @value.setter  # L1-019-property
    def value(self, value: str) -> None:
        normalized = value.strip().casefold()
        if not normalized:
            raise DataError("category must not be empty")
        self._value = normalized


@lru_cache(maxsize=256)  # L1-032-lru-cache
def parse_money(text: str) -> int:
    if re.fullmatch(r"[0-9]+(?:\.[0-9]{1,2})?", text) is None:
        raise DataError("amount must be a non-negative number with at most two decimals")
    whole, _, fraction = text.partition(".")
    return int(whole) * 100 + int((fraction + "00")[:2])  # L1-005-index-slice


def format_money(cents: int) -> str:
    if isinstance(cents, bool) or not isinstance(cents, int):  # L1-026-numbers-bool
        raise TypeError("money must be integer cents, not bool")
    if cents < 0:
        raise DataError("money must not be negative")
    return f"{cents // 100}.{cents % 100:02d}"  # L1-006-functions-return


def read_records(path: Path) -> Iterator[Record]:
    with path.open(encoding="utf-8-sig", newline="") as stream:  # L2-010-pathlib-io
        reader = csv.reader(stream, strict=True)
        try:
            header = next(reader, None)
            if header is None or [cell.strip() for cell in header] != [
                "date",
                "category",
                "amount",
            ]:
                raise DataError("expected header: date,category,amount")
            for fields in reader:
                if not fields or not any(  # L1-025-truthiness-short-circuit
                    cell.strip() for cell in fields
                ):
                    continue
                if len(fields) != 3:
                    raise DataError(f"line {reader.line_num}: expected three fields")
                day, category, amount = (  # L1-024-unpacking
                    cell.strip() for cell in fields
                )
                try:
                    if re.fullmatch(r"[0-9]{4}-[0-9]{2}-[0-9]{2}", day) is None:
                        raise ValueError("date must use YYYY-MM-DD")
                    date.fromisoformat(day)
                    record = Record(day, Category(category).value, parse_money(amount))
                except ValueError as exc:
                    raise DataError(
                        f"line {reader.line_num}: {exc}"
                    ) from exc  # L1-016-exceptions-chain
                yield record  # L1-014-generators-lazy
        except csv.Error as exc:
            raise DataError(f"line {reader.line_num}: malformed CSV: {exc}") from exc


def unique_records(
    records: Iterable[Record],
    /,
    *,
    seen: set[Record] | None = None,  # L1-008-function-signature
) -> Iterator[Record]:
    keys = set() if seen is None else seen  # L1-007-mutable-default
    for record in records:
        if record not in keys:
            keys.add(record)  # L1-020-eq-hash
            yield record


def write_clean(records: Iterable[Record], path: Path) -> int:
    count = 0
    with path.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.writer(stream, lineterminator="\n")
        writer.writerow(("date", "category", "amount"))
        for record in unique_records(records):
            writer.writerow((record.day, record.category, format_money(record.cents)))
            count += 1
    return count


def aggregate(records: Iterable[Record]) -> list[Group]:
    counts: Counter[str] = Counter()  # L1-023-collections
    totals: defaultdict[str, int] = defaultdict(int)
    for record in records:
        counts[record.category] += 1
        totals[record.category] += record.cents
    return [
        Group(category, counts[category], totals[category])
        for category in sorted(counts, key=str.casefold)  # L1-028-sorting-key
    ]


def render_table(headings: Sequence[str], rows: Iterable[TableRow]) -> str:
    data = [
        list(headings),
        *(list(row.cells()) for row in rows),  # L1-012-comprehensions
    ]
    if not headings:
        raise ValueError("table needs at least one column")
    if any(len(row) != len(headings) for row in data):
        raise ValueError("table rows must match headings")
    widths = [max(len(row[i]) for row in data) for i in range(len(headings))]
    lines = [" | ".join(cell.ljust(width) for cell, width in zip(row, widths)) for row in data]
    lines.insert(1, "-+-".join("-" * width for width in widths))
    assert all(len(line) == len(lines[0]) for line in lines)  # L1-031-assert-invariants
    return "\n".join(lines)
