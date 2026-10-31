#include <iostream>
#include <string_view>

class Base {
public:
    virtual ~Base() = default;
    virtual std::string_view kind() const { return "Base"; }
};

class Derived : public Base {
public:
    std::string_view kind() const override { return "Derived"; }
};

int main() {
    Derived object;
    Base* pointer = &object;

    std::cout << "static type: Base*\n";
    std::cout << "virtual call: " << pointer->kind() << '\n';
}
