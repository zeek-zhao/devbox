#include <iostream>

int triple(int value) {
  return value * 3;
}

struct AddOffset {
  int operator()(int value) const {
    return value + 4;
  }
};

int call_function_pointer(int value, int (*callback)(int)) {
  return callback(value);
}

template <typename Callback>
int call_callable(int value, Callback callback) {
  return callback(value);
}

int main() {
  const int function_result = call_function_pointer(5, triple);
  const int function_object_result = call_callable(5, AddOffset{});
  const int captured_value = 6;
  const auto captured_callback = [captured_value](int value) {
    return value + captured_value;
  };
  const int lambda_result = call_callable(5, captured_callback);

  std::cout << "function pointer: " << function_result << '\n';
  std::cout << "function object: " << function_object_result << '\n';
  std::cout << "capturing lambda: " << lambda_result << '\n';
}
