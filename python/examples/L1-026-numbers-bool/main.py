from decimal import Decimal


def accepts_count(value):
    return isinstance(value, int) and not isinstance(value, bool)


print("True equals 1:", True == 1)
print("True is an int:", isinstance(True, int))
print("accepts True as count:", accepts_count(True))
print("accepts 1 as count:", accepts_count(1))
print("decimal sum is exact:", Decimal("0.1") + Decimal("0.2") == Decimal("0.3"))
