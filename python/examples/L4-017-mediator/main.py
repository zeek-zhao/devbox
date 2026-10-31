class Mediator:
    def __init__(self):
        self._colleagues = {}

    def register(self, colleague):
        if colleague.name in self._colleagues:
            raise ValueError("duplicate colleague")
        self._colleagues[colleague.name] = colleague

    def forward(self, sender, recipient, message):
        if self._colleagues.get(sender.name) is not sender:
            raise ValueError("sender is not registered")
        self._colleagues[recipient].receive(sender.name, message)


class Colleague:
    def __init__(self, name, mediator):
        self.name = name
        self._mediator = mediator

    def send(self, recipient, message):
        self._mediator.forward(self, recipient, message)

    def receive(self, sender, message):
        print(f"{sender} -> {self.name}: {message}")


def main():
    mediator = Mediator()
    editor = Colleague("editor", mediator)
    preview = Colleague("preview", mediator)
    status = Colleague("status", mediator)
    for colleague in (editor, preview, status):
        mediator.register(colleague)
    editor.send("preview", "document changed")
    preview.send("status", "render complete")
    status.send("editor", "saved")


if __name__ == "__main__":
    main()
