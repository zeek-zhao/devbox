#include <iostream>
#include <memory>
#include <utility>

class Buffer {
 public:
  explicit Buffer(int value)
      : data_{std::make_unique<int[]>(1)} {
    data_[0] = value;
  }

  Buffer(const Buffer&) = delete;
  Buffer& operator=(const Buffer&) = delete;

  Buffer(Buffer&& other) noexcept
      : data_{std::move(other.data_)} {
    std::cout << "move-construct\n";
  }

  ~Buffer() { std::cout << "destroy buffer\n"; }

  int value() const { return data_[0]; }

 private:
  std::unique_ptr<int[]> data_;
};

int main() {
  {
    Buffer source{42};
    Buffer destination{std::move(source)};
    std::cout << "destination value: " << destination.value() << '\n';
    std::cout << "moved-from source remains valid for destruction\n";
  }
}
