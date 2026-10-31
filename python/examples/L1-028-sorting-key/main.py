records = [("Mina", 2), ("Omar", 1), ("Lia", 1)]
ordered = sorted(records, key=lambda record: record[1])
print("sorted records:", ordered)
print("input preserved:", records == [("Mina", 2), ("Omar", 1), ("Lia", 1)])

in_place = list(records)
sort_result = in_place.sort(key=lambda record: record[1])
print("sort returns None:", sort_result is None)
print("in-place records:", in_place)
