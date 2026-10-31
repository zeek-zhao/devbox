class ReportField:
    def __init__(self, value):
        self.value = value

    @property
    def value(self):
        return self._value

    @value.setter
    def value(self, value):
        if not isinstance(value, str) or not value.strip():
            raise ValueError("value must be a non-empty string")
        self._value = value.strip()


field = ReportField("  ready  ")
print(f"value: {field.value}")
try:
    field.value = "   "
except ValueError as err:
    print(f"invalid assignment: {type(err).__name__}")
