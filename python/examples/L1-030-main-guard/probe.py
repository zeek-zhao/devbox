import contextlib
import importlib
import io


captured = io.StringIO()
with contextlib.redirect_stdout(captured):
    importlib.import_module("main")

print("import output empty:", captured.getvalue() == "")
