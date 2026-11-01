"""Subcommands share the same validation and aggregation pipeline."""

import argparse
from collections.abc import Sequence
from pathlib import Path

from .core import (
    DataError,
    read_records,
    write_clean,
)
from .reporting import FullReportJob, SummaryJob

SAMPLE = (
    "date,category,amount\n"
    "2026-01-01, Food ,12.50\n"
    "2026-01-02,books,20\n"
    "\n"
    "2026-01-01,food,12.50\n"
    "2026-01-03,FOOD,0.10\n"
)


class Workspace:
    """Own an exclusively created directory and clean it on either exit path."""

    def __init__(self, path: Path) -> None:
        self.path = path

    def __enter__(self) -> Path:
        self.path.mkdir()
        return self.path

    def __exit__(  # L1-015-context-managers
        self, kind: object, value: object, traceback: object
    ) -> None:
        for child in self.path.iterdir():
            child.unlink()
        self.path.rmdir()


class AtomicOutput:
    """Reserve a sibling temporary file; publish only after complete validation."""

    def __init__(self, target: Path) -> None:
        self.target = target
        self.temporary = target.with_name(target.name + ".tmp")

    def __enter__(self) -> Path:
        with self.temporary.open("x", encoding="utf-8"):
            pass
        return self.temporary

    def __exit__(self, kind: object, value: object, traceback: object) -> None:
        try:
            if kind is None:
                self.temporary.replace(self.target)
        finally:
            if self.temporary.exists():
                self.temporary.unlink()


def execute(  # L4-010-facade
    command: str, source: Path, output: Path | None = None
) -> str:
    if command not in ("clean", "summary", "report"):
        raise DataError(f"unknown command: {command}")
    if command == "clean":
        if output is None:
            raise DataError("clean requires an output file")
        with AtomicOutput(output) as temporary:
            count = write_clean(read_records(source), temporary)
        return f"clean: {count} rows"
    if command == "summary":
        return SummaryJob().execute(read_records(source))
    return FullReportJob().execute(read_records(source))


def self_check() -> str:
    with Workspace(Path("/tmp/devbox-python-self-check")) as workspace:
        source = workspace / "input.csv"
        clean = workspace / "clean.csv"
        source.write_text(SAMPLE, encoding="utf-8")
        # Exercise the same argparse entry and dispatch as real CLI calls.
        result = [
            run(["clean", str(source), str(clean)]),
            clean.read_text(encoding="utf-8").rstrip("\n"),
            "summary:",
            run(["summary", str(clean)]),
            "report:",
            run(["report", str(clean)]),
        ]
        return "\n".join(result)


def run(argv: Sequence[str] | None = None) -> str:
    parser = argparse.ArgumentParser(description="Clean CSV and print deterministic reports")
    parser.add_argument("--self-check", action="store_true")
    commands = parser.add_subparsers(dest="command")  # L2-007-argparse-cli
    for name in ("clean", "summary", "report"):
        command = commands.add_parser(name)
        command.add_argument("input", type=Path)
        if name == "clean":
            command.add_argument("output", type=Path)
    args = parser.parse_args(argv)
    try:
        if args.self_check:
            if args.command is not None:
                parser.error("--self-check cannot be combined with a subcommand")
            return self_check()
        if args.command is None:
            parser.error("choose clean, summary or report")
        return execute(args.command, args.input, getattr(args, "output", None))
    except (OSError, UnicodeError, DataError) as exc:
        parser.error(str(exc))


def main() -> None:
    print(run())
