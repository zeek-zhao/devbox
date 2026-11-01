#include <algorithm>
#include <iostream>
#include <vector>

int main() {
    std::vector<int> values{4, 1, 3, 2};
    std::sort(values.begin(), values.end());

    const auto found = std::find(values.begin(), values.end(), 3);
    std::cout << "found: " << (found != values.end()) << '\n';

    values.erase(found);
    std::cout << "after erase:";
    for (const int value : values) {
        std::cout << ' ' << value;
    }
    std::cout << '\n';

    const auto new_begin = values.begin();
    std::cout << "new begin: " << *new_begin << '\n';
}
