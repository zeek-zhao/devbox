import json
from importlib.resources import files


def main() -> None:
    resource = files("report_bundle").joinpath("defaults.json")
    settings = json.loads(resource.read_text(encoding="utf-8"))
    print(f"template: {settings['template']}")
    print(f"page size: {settings['page_size']}")


if __name__ == "__main__":
    main()
