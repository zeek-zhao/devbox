#include <iostream>
#include <vector>

int check_count = 0;
int failure_count = 0;

#define CHECK(expression)                                                                          \
    do {                                                                                           \
        ++check_count;                                                                             \
        if (!(expression)) {                                                                       \
            ++failure_count;                                                                       \
            std::cerr << "check failed at line " << __LINE__ << ": " #expression << '\n';          \
        }                                                                                          \
    } while (false)

int find_index(const std::vector<int>& values, int target) {
    for (std::size_t index = 0; index < values.size(); ++index) {
        if (values[index] == target) {
            return static_cast<int>(index);
        }
    }
    return -1;
}

int main() {
    const std::vector<int> values{4, 8, 15, 16, 23, 42};

    CHECK(find_index(values, 15) == 2);
    CHECK(find_index(values, 4) == 0);
    CHECK(find_index(values, 42) == 5);
    CHECK(find_index(values, 7) == -1);
    CHECK(find_index({}, 7) == -1);

    const int passed_count = check_count - failure_count;
    std::cout << "passed: " << passed_count << " failed: " << failure_count << '\n';
    return failure_count == 0 ? 0 : 1;
}
