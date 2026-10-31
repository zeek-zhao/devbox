class ReportRow:
    shared_labels = []

    def __init__(self, name):
        self.name = name
        self.values = []


first = ReportRow("first")
second = ReportRow("second")
first.values.append("one")
ReportRow.shared_labels.append("reviewed")

print(f"first values: {first.values}")
print(f"second values: {second.values}")
print(f"shared labels: {first.shared_labels}, {second.shared_labels}")
