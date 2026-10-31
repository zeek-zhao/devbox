late_bound = [lambda: index for index in range(3)]
fixed = [lambda index=index: index for index in range(3)]

print(f"late-bound values: {[function() for function in late_bound]}")
print(f"fixed values: {[function() for function in fixed]}")
