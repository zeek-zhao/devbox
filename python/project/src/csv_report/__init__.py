"""Standard-library CSV cleaning and deterministic reporting."""

from .core import (  # L2-001-package-imports
    Record,
    aggregate,
    read_records,
    render_table,
)

__all__ = ["Record", "aggregate", "read_records", "render_table"]
