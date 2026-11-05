"""T-001-venv-mix-mutable-default 被测程序：两个相互独立的缺陷。

缺陷 1（环境串味，素材 S-13）：import 跟解释器环境走，与代码写在哪儿无关。
本 lab 只把占位包 myproj 放进 venvA 的 site-packages——venvB 的解释器跑本文件
必报 ModuleNotFoundError；一旦 PYTHONPATH 指向 venvA，venvB 又能「串味」成功 import。

缺陷 2（可变默认参数）：build_cart 的默认列表在多次调用间是同一个对象，跨调用累积。
"""

import sys


def build_cart(item, items=[]):
    # 缺陷 2：默认参数 items=[] 只在函数定义时创建一次，所有调用共享同一个列表对象。
    items.append(item)
    return items


def load_myproj():
    # 缺陷 1：import myproj 解析到「当前解释器环境」的 sys.path，与代码文件位置无关。
    import myproj

    return myproj.VERSION


def main():
    print("env: start")
    print(f"sys.executable={sys.executable}")
    cart1 = build_cart("apple")
    cart2 = build_cart("banana")
    print(f"cart call1={cart1}")
    print(f"cart call2={cart2}")
    print(f"myproj={load_myproj()}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
