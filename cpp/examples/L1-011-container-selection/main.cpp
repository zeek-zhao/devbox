#include <iostream>
#include <map>
#include <utility>
#include <vector>

int main() {
    const std::vector<std::pair<int, int>> entries{{1, 10}, {2, 20}, {3, 30}};
    std::vector<std::pair<int, int>> vector_entries;
    for (const auto& entry : entries) {
        vector_entries.push_back(entry);
    }

    const auto vector_match = [&vector_entries](int key) {
        for (const auto& entry : vector_entries) {
            if (entry.first == key) {
                return entry.second;
            }
        }
        return -1;
    }(2);

    std::map<int, int> map_entries;
    for (const auto& entry : entries) {
        map_entries.insert(entry);
    }
    const auto map_position = map_entries.find(2);
    const auto map_match = map_position == map_entries.end() ? -1 : map_position->second;

    std::cout << "vector lookup: " << vector_match << '\n';
    std::cout << "map lookup: " << map_match << '\n';
    std::cout << std::boolalpha << "results match: " << (vector_match == map_match) << '\n';
}
