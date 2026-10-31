import argparse
from contextlib import redirect_stderr, redirect_stdout
from io import StringIO


parser = argparse.ArgumentParser(description="Build a report")
parser.add_argument("source")
parser.add_argument("--limit", type=int, default=10)

args = parser.parse_args(["records.csv", "--limit", "3"])
print(f"valid args: source={args.source} limit={args.limit}")

with redirect_stderr(StringIO()):
    try:
        parser.parse_args(["--limit", "3"])
    except SystemExit as error:
        missing_rejected = error.code == 2
print(f"missing argument: {'rejected' if missing_rejected else 'accepted'}")

with redirect_stdout(StringIO()), redirect_stderr(StringIO()):
    try:
        parser.parse_args(["--help"])
    except SystemExit as error:
        help_succeeded = error.code == 0
print(f"help: {'available' if help_succeeded else 'failed'}")
