from subprocess import run


def load_records() -> str:
    result = run(
        ["report-tool", "--format", "json"],
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout
