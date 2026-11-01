"""用例 hello：确认 python3.12 可用、dataclass 与类型标注正常"""

import sys
from dataclasses import dataclass


@dataclass
class Point:
    x: int
    y: int


def main() -> None:
    print("[hello] Python from devbox")
    # 只打印 major.minor，不打印完整版本：补丁号会随镜像更新变化
    print(f"major.minor = {sys.version_info.major}.{sys.version_info.minor}")

    p = Point(3, 4)
    print(f"dist = {(p.x**2 + p.y**2) ** 0.5:.0f}")
    print(f"sum(1..100) = {sum(range(1, 101))}")


if __name__ == "__main__":
    main()
