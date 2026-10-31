from abc import ABC, abstractmethod


class Button(ABC):
    @property
    @abstractmethod
    def family(self) -> str:
        raise NotImplementedError


class TextBox(ABC):
    @property
    @abstractmethod
    def family(self) -> str:
        raise NotImplementedError


class LightButton(Button):
    family = "light"


class LightTextBox(TextBox):
    family = "light"


class DarkButton(Button):
    family = "dark"


class DarkTextBox(TextBox):
    family = "dark"


class WidgetFactory(ABC):
    @abstractmethod
    def create_button(self) -> Button:
        raise NotImplementedError

    @abstractmethod
    def create_text_box(self) -> TextBox:
        raise NotImplementedError


class LightFactory(WidgetFactory):
    def create_button(self) -> Button:
        return LightButton()

    def create_text_box(self) -> TextBox:
        return LightTextBox()


class DarkFactory(WidgetFactory):
    def create_button(self) -> Button:
        return DarkButton()

    def create_text_box(self) -> TextBox:
        return DarkTextBox()


def describe(factory: WidgetFactory) -> str:
    button = factory.create_button()
    text_box = factory.create_text_box()
    print("family:", button.family, text_box.family)
    print("matched:", button.family == text_box.family)
    assert isinstance(button, Button)
    assert isinstance(text_box, TextBox)
    assert button.family == text_box.family
    return button.family


def main():
    light = describe(LightFactory())
    dark = describe(DarkFactory())
    print("different families:", light != dark)
    assert light != dark


if __name__ == "__main__":
    main()
