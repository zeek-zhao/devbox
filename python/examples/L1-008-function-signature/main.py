def dispatch(command, /, *items, mode, **options):
    return command, items, mode, options


command, items, mode, options = dispatch(
    "export", "summary", "detail", mode="safe", limit=3, dry_run=True
)
print(f"command: {command}")
print(f"extra positional: {items}")
print(f"keyword-only mode: {mode}")
print(f"extra keywords: {options}")

try:
    dispatch(command="export", mode="safe")
except TypeError:
    print("positional-only keyword rejected: True")
