#include <iostream>
#include <memory>
#include <type_traits>

class PlainBase {
public:
    ~PlainBase() { std::cout << "plain base destructor\n"; }
};

class PlainDerived : public PlainBase {
public:
    ~PlainDerived() { std::cout << "plain derived destructor\n"; }
};

class VirtualBase {
public:
    virtual ~VirtualBase() { std::cout << "virtual base destructor\n"; }
};

class VirtualDerived : public VirtualBase {
public:
    ~VirtualDerived() override { std::cout << "virtual derived destructor\n"; }
};

int main() {
    std::cout << std::boolalpha;
    std::cout << "plain base has virtual destructor: "
              << std::has_virtual_destructor_v<PlainBase> << '\n';
    { PlainDerived object; }

    std::cout << "virtual base has virtual destructor: "
              << std::has_virtual_destructor_v<VirtualBase> << '\n';
    { std::unique_ptr<VirtualBase> object = std::make_unique<VirtualDerived>(); }
}
