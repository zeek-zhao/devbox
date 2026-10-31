class Base:
    def __init__(self, events):
        events.append("Base")

    def render(self):
        return ["Base"]


class AuditMixin(Base):
    def __init__(self, events):
        events.append("AuditMixin")
        super().__init__(events)

    def render(self):
        return super().render() + ["AuditMixin"]


class LabelMixin(Base):
    def __init__(self, events):
        events.append("LabelMixin")
        super().__init__(events)

    def render(self):
        return super().render() + ["LabelMixin"]


class Report(AuditMixin, LabelMixin):
    def __init__(self, events):
        events.append("Report")
        super().__init__(events)

    def render(self):
        return super().render() + ["Report"]


events = []
report = Report(events)
print("initialization MRO:", " then ".join(events))
print("render MRO:", " then ".join(report.render()))
