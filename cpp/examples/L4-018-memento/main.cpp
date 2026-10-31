#include <iostream>
#include <string>
#include <string_view>
#include <type_traits>
#include <utility>

class Editor {
public:
    class Memento {
    public:
        const std::string& text() const { return text_; }
        int cursor() const { return cursor_; }

    private:
        friend class Editor;
        Memento(std::string text, int cursor)
            : text_(std::move(text)), cursor_(cursor) {}
        const std::string text_;
        const int cursor_;
    };

    Editor(std::string text, int cursor)
        : text_(std::move(text)), cursor_(cursor) {}
    void edit(std::string text, int cursor) {
        text_ = std::move(text);
        cursor_ = cursor;
    }
    Memento save() const { return Memento(text_, cursor_); }
    void restore(const Memento& memento) {
        text_ = memento.text_;
        cursor_ = memento.cursor_;
    }
    void show(std::string_view label) const {
        std::cout << label << ": " << text_ << ", cursor=" << cursor_ << '\n';
    }

private:
    std::string text_;
    int cursor_;
};

static_assert(!std::is_copy_assignable_v<Editor::Memento>);
static_assert(std::is_same_v<decltype(std::declval<Editor::Memento&>().text()),
                             const std::string&>);

int main() {
    Editor editor("draft", 2);
    const auto checkpoint = editor.save();
    editor.show("before");
    editor.edit("published", 9);
    editor.show("changed");
    editor.restore(checkpoint);
    editor.show("restored");
    std::cout << "snapshot: " << checkpoint.text()
              << ", cursor=" << checkpoint.cursor() << '\n';
}
