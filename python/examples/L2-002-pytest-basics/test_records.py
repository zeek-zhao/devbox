import pytest


@pytest.fixture
def records() -> list[str]:
    return ["alpha", "beta"]


@pytest.mark.parametrize(
    ("value", "expected"),
    [("alpha", True), ("gamma", False)],
)
def test_record_membership(records: list[str], value: str, expected: bool) -> None:
    assert (value in records) is expected


def test_missing_record_raises(records: list[str]) -> None:
    with pytest.raises(ValueError, match="record not found"):
        find_record(records, "gamma")


def find_record(records: list[str], value: str) -> str:
    if value not in records:
        raise ValueError("record not found")
    return value


def test_tmp_path_is_isolated(tmp_path) -> None:
    output = tmp_path / "report.txt"
    output.write_text("ready", encoding="utf-8")
    assert output.read_text(encoding="utf-8") == "ready"
