"""E-004 EAFP vs LBYL：同一缺失场景的两条路径，EAFP 消除检查与使用之间的窗口。"""

CONFIG = {"retries": 3}


def lbyl_read(key, default):
    if key in CONFIG:  # 先检查再使用：两步之间状态可能被其他线程改掉
        return CONFIG[key]
    return default


def eafp_read(key, default):
    try:
        return CONFIG[key]
    except KeyError:  # 直接使用，缺失作为异常处理：检查与使用是同一原子动作
        return default


print(f"lbyl-hit: got {lbyl_read('retries', 0)}")
print(f"lbyl-miss: {lbyl_read('timeout', 'default')}")
print(f"eafp-hit: got {eafp_read('retries', 0)}")
print(f"eafp-miss: {eafp_read('timeout', 'default')}")
print("verdict: EAFP collapses check and use into one step, closing the check-then-use window")
