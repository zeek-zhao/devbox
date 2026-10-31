from pathlib import Path
import subprocess
import sys

from .app.core import greeting


package_root = Path(__file__).parent.parent
direct_run = subprocess.run(
    [sys.executable, str(package_root / "app" / "core.py")],
    cwd=package_root.parent,
    capture_output=True,
    text=True,
    check=False,
)
if direct_run.returncode == 0:
    raise RuntimeError("direct execution unexpectedly succeeded")

print("direct file execution: rejected")
print(f"module import: {greeting()}")
