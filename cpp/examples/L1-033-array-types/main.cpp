#include <array>
#include <iostream>
#include <iterator>
#include <vector>

void print_decayed_size(int* values) {
    std::cout << "sizeof decayed parameter: " << sizeof(values) << '\n';
}

int main() {
    int c_array[]{10, 20, 30};
    const std::array<int, 3> fixed_array{10, 20, 30};
    std::vector<int> dynamic_array{10, 20, 30};
    dynamic_array.push_back(40);

    std::cout << "C array length: " << std::size(c_array) << '\n';
    std::cout << "sizeof C array: " << sizeof(c_array) << '\n';
    print_decayed_size(c_array);
    std::cout << "std::array length: " << std::size(fixed_array) << '\n';
    std::cout << "std::vector length: " << std::size(dynamic_array) << '\n';
}
