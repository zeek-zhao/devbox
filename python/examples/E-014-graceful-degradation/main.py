"""E-014 优雅降级：主路径失败回退备用路径，失败原因逐条留痕，全败才整体失败。"""


class SourceError(Exception):
    """数据源不可用：按 message 前缀区分 TRANSIENT / PERMANENT（演示用）。"""


def primary_db():
    raise SourceError("TRANSIENT primary-db offline")


def cache_snapshot():
    return "stale-snapshot"


def archive_copy():
    raise SourceError("PERMANENT archive unreadable")


def load(sources):
    """按顺序尝试数据源；返回 (结果, 服务方, 失败记录)；全部失败抛 RuntimeError。"""
    failures = []
    for name, loader in sources:
        try:
            result = loader()
        except SourceError as err:
            failures.append(f"{name}: {err}")
        else:
            return result, name, failures
    raise RuntimeError("; ".join(failures))


def main():
    result, served_by, failures = load([("primary-db", primary_db), ("cache", cache_snapshot)])
    print(f"primary failed: {failures[0]}")
    print(f"fallback: {result} (served by {served_by})")
    print(f"degradation: failed-sources={len(failures)}")

    try:
        load([("primary-db", primary_db), ("archive", archive_copy)])
    except RuntimeError as err:
        print(f"no-source: {err}")
    print("rule: degrade with recorded reasons; fail only when every path is down")


if __name__ == "__main__":
    main()
