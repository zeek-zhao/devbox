from functools import lru_cache


@lru_cache(maxsize=None)
def fibonacci(value: int) -> int:
    if value < 2:
        return value
    return fibonacci(value - 1) + fibonacci(value - 2)


print(f"fib(8): {fibonacci(8)}")
fibonacci(8)
info = fibonacci.cache_info()
print(f"cache hits: {info.hits}")
print(f"cache misses: {info.misses}")

try:
    fibonacci([8])
except TypeError:
    print("unhashable argument: rejected")

fibonacci.cache_clear()
print(f"cache cleared: {fibonacci.cache_info().currsize == 0}")
