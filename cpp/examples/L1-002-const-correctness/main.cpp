#include <iostream>
#include <type_traits>

class Item {
public:
    explicit Item(int value) : value_{value} {}

    int value() const { return value_; }
    void set_value(int value) { value_ = value; }

private:
    int value_;
};

int read_value(const Item& item) {
    return item.value();
}

int main() {
    const Item item{7};
    using Setter = void (Item::*)(int);

    std::cout << "read-only value: " << read_value(item) << '\n';
    std::cout << "mutable interface callable on const object: " << std::boolalpha
              << std::is_invocable_v<Setter, const Item&, int> << '\n';
}
