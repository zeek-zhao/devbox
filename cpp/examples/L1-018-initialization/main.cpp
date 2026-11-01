#include <iostream>
#include <vector>

int main() {
    std::vector<int> list_initialized{10, 20};
    std::vector<int> directly_initialized(10, 20);

    std::cout << "braces: size=" << list_initialized.size() << " values=" << list_initialized[0]
              << ',' << list_initialized[1] << '\n';
    std::cout << "parentheses: size=" << directly_initialized.size()
              << " first=" << directly_initialized.front()
              << " last=" << directly_initialized.back() << '\n';

    // A narrowing expression such as int{3.7} is ill-formed; do not compile it here.
}
