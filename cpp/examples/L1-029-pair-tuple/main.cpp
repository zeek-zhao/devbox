#include <iostream>
#include <string>
#include <tuple>
#include <utility>

std::pair<std::string, int> make_entry() {
    return {"widget", 3};
}

std::tuple<std::string, int, bool> make_summary() {
    return {"widget", 12, true};
}

int main() {
    const auto entry = make_entry();
    std::cout << "pair key: " << std::get<0>(entry) << '\n';
    std::cout << "pair count: " << std::get<1>(entry) << '\n';

    std::string name;
    int total = 0;
    bool complete = false;
    std::tie(name, total, complete) = make_summary();
    std::cout << "tuple: " << name << ", " << total << ", " << std::boolalpha << complete << '\n';
}
