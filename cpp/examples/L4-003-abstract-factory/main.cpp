#include <iostream>
#include <memory>
#include <string_view>
#include <type_traits>
#include <utility>

struct LightFamily {};
struct DarkFamily {};

template <typename Family> class Button {
public:
    virtual ~Button() = default;
    virtual std::string_view family() const = 0;
};

template <typename Family> class TextBox {
public:
    virtual ~TextBox() = default;
    virtual std::string_view family() const = 0;
};

template <typename Family> class Factory {
public:
    virtual ~Factory() = default;
    virtual std::unique_ptr<Button<Family>> create_button() const = 0;
    virtual std::unique_ptr<TextBox<Family>> create_text_box() const = 0;
};

class LightButton final : public Button<LightFamily> {
public:
    std::string_view family() const override { return "light"; }
};

class LightTextBox final : public TextBox<LightFamily> {
public:
    std::string_view family() const override { return "light"; }
};

class DarkButton final : public Button<DarkFamily> {
public:
    std::string_view family() const override { return "dark"; }
};

class DarkTextBox final : public TextBox<DarkFamily> {
public:
    std::string_view family() const override { return "dark"; }
};

class LightFactory final : public Factory<LightFamily> {
public:
    std::unique_ptr<Button<LightFamily>> create_button() const override {
        return std::make_unique<LightButton>();
    }
    std::unique_ptr<TextBox<LightFamily>> create_text_box() const override {
        return std::make_unique<LightTextBox>();
    }
};

class DarkFactory final : public Factory<DarkFamily> {
public:
    std::unique_ptr<Button<DarkFamily>> create_button() const override {
        return std::make_unique<DarkButton>();
    }
    std::unique_ptr<TextBox<DarkFamily>> create_text_box() const override {
        return std::make_unique<DarkTextBox>();
    }
};

template <typename Family> class Panel {
public:
    Panel(std::unique_ptr<Button<Family>> button, std::unique_ptr<TextBox<Family>> text_box)
        : button_(std::move(button)), text_box_(std::move(text_box)) {}

    std::string_view render() const {
        std::cout << "button: " << button_->family() << ", text box: " << text_box_->family()
                  << '\n';
        std::cout << "matching family: " << (button_->family() == text_box_->family()) << '\n';
        return button_->family();
    }

private:
    std::unique_ptr<Button<Family>> button_;
    std::unique_ptr<TextBox<Family>> text_box_;
};

static_assert(!std::is_constructible_v<Panel<LightFamily>, std::unique_ptr<Button<LightFamily>>,
                                       std::unique_ptr<TextBox<DarkFamily>>>);

template <typename Family> std::string_view use_factory(const Factory<Family>* factory) {
    Panel<Family> panel(factory->create_button(), factory->create_text_box());
    return panel.render();
}

int main() {
    std::cout << std::boolalpha;
    const std::unique_ptr<Factory<LightFamily>> light = std::make_unique<LightFactory>();
    const std::unique_ptr<Factory<DarkFamily>> dark = std::make_unique<DarkFactory>();
    const auto light_family = use_factory(light.get());
    const auto dark_family = use_factory(dark.get());
    std::cout << "different families: " << (light_family != dark_family) << '\n';
}
