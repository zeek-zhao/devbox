#include <iostream>
#include <stdexcept>
#include <string>
#include <utility>

class Setting {
 public:
  explicit Setting(std::string value) : value_(std::move(value)) {}

  void replace(std::string candidate) {
    if (candidate.empty()) {
      throw std::invalid_argument("setting cannot be empty");
    }
    value_.swap(candidate);
  }

  const std::string& value() const { return value_; }

 private:
  std::string value_;
};

int main() {
  Setting setting{"stable"};
  std::cout << "before: " << setting.value() << '\n';

  try {
    setting.replace("");
  } catch (const std::invalid_argument&) {
    std::cout << "operation: failed\n";
  }

  std::cout << "after: " << setting.value() << '\n';
}
