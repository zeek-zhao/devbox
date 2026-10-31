from unittest.mock import patch

import service


def main() -> None:
    with patch("service.run") as run_mock:
        run_mock.return_value.stdout = '{"records": 2}'
        records = service.load_records()
        run_mock.assert_called_once_with(
            ["report-tool", "--format", "json"],
            check=True,
            capture_output=True,
            text=True,
        )

    print(f"mocked response: {records}")
    print("external command calls: 1")
    print("arguments verified: true")


if __name__ == "__main__":
    main()
