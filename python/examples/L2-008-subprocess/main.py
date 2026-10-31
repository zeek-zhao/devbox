import subprocess
import sys


result = subprocess.run(
    [
        sys.executable,
        "-c",
        "import sys; sys.stdout.write('|'.join(sys.argv[1:]))",
        "alpha",
        "two words",
    ],
    check=True,
    capture_output=True,
    text=True,
)
print(f"child output: {result.stdout}")

try:
    subprocess.run(
        [sys.executable, "-c", "raise SystemExit(4)"],
        check=True,
        capture_output=True,
        text=True,
    )
except subprocess.CalledProcessError:
    print("nonzero status: caught")
