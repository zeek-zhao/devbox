import os
from pathlib import Path
from tempfile import TemporaryDirectory


def main() -> None:
    base = Path(os.environ.get("TMPDIR", "/tmp")) / "devbox-python-L2-010-pathlib-io"
    base.mkdir(parents=True, exist_ok=True)
    with TemporaryDirectory(dir=base) as directory:
        report = Path(directory) / "reports" / "daily.txt"
        report.parent.mkdir()
        report.write_text("ready\n", encoding="utf-8")
        print(f"round trip: {report.read_text(encoding='utf-8') == 'ready\n'}")

        empty = report.with_name("empty.txt")
        empty.write_text("", encoding="utf-8")
        print(f"empty file: {empty.read_text(encoding='utf-8') == ''}")

        missing = report.with_name("missing.txt")
        try:
            missing.read_text(encoding="utf-8")
        except FileNotFoundError as error:
            print(f"missing error: {type(error).__name__}")


if __name__ == "__main__":
    main()
