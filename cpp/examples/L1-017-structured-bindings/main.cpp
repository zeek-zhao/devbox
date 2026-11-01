#include <iostream>
#include <tuple>

struct Entry {
    int key;
    int value;
};

int main() {
    std::tuple<int, int> tuple_entry{1, 10};
    auto [tuple_key_copy, tuple_value_copy] = tuple_entry;
    tuple_value_copy = 99;
    auto& [tuple_key_ref, tuple_value_ref] = tuple_entry;
    tuple_value_ref = 20;

    std::cout << "tuple copy value: " << tuple_value_copy << '\n';
    std::cout << "tuple original: " << std::get<0>(tuple_entry) << ',' << std::get<1>(tuple_entry)
              << '\n';

    Entry aggregate{2, 30};
    auto [aggregate_key_copy, aggregate_value_copy] = aggregate;
    aggregate_value_copy = 99;
    auto& [aggregate_key_ref, aggregate_value_ref] = aggregate;
    aggregate_value_ref = 40;

    std::cout << "aggregate copy value: " << aggregate_value_copy << '\n';
    std::cout << "aggregate original: " << aggregate.key << ',' << aggregate.value << '\n';

    (void)tuple_key_copy;
    (void)tuple_key_ref;
    (void)tuple_value_ref;
    (void)aggregate_key_copy;
    (void)aggregate_key_ref;
    (void)aggregate_value_ref;
}
