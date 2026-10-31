#include <iostream>

struct Base {
  virtual ~Base() = default;
};

struct Derived : Base {};

struct Unrelated : Base {};

int main() {
  const double measurement = 4.75;
  const int rounded_down = static_cast<int>(measurement);
  std::cout << "static_cast numeric: " << rounded_down << '\n';

  Derived derived;
  Base* base = static_cast<Base*>(&derived);
  std::cout << "static_cast upcast: " << (base != nullptr) << '\n';

  int mutable_value = 7;
  const int& read_only_view = mutable_value;
  const_cast<int&>(read_only_view) = 9;
  std::cout << "const_cast on mutable object: " << mutable_value << '\n';

  Unrelated unrelated;
  Base* polymorphic = &unrelated;
  Derived* checked = dynamic_cast<Derived*>(polymorphic);
  std::cout << "dynamic_cast failed: " << (checked == nullptr) << '\n';

  const unsigned char* object_bytes =
      reinterpret_cast<const unsigned char*>(&mutable_value);
  std::cout << "reinterpret_cast byte size: " << sizeof(*object_bytes) << '\n';
}
