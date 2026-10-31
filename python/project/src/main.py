"""CSV processing CLI; importing this module never starts the command."""

from csv_report.cli import main

if __name__ == "__main__":  # L1-030-main-guard
    main()
