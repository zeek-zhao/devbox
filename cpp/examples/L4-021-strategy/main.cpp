#include <algorithm>
#include <functional>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <utility>
#include <vector>

class SortStrategy {
public:
    virtual ~SortStrategy() = default;
    virtual std::vector<int> sort(std::vector<int> values) const = 0;
};

class Ascending final : public SortStrategy {
public:
    std::vector<int> sort(std::vector<int> values) const override {
        std::sort(values.begin(), values.end());
        return values;
    }
};

class Descending final : public SortStrategy {
public:
    std::vector<int> sort(std::vector<int> values) const override {
        std::sort(values.begin(), values.end(), std::greater<int>{});
        return values;
    }
};

class Sorter {
public:
    explicit Sorter(std::unique_ptr<SortStrategy> strategy) { set_strategy(std::move(strategy)); }
    void set_strategy(std::unique_ptr<SortStrategy> strategy) {
        if (!strategy) {
            throw std::invalid_argument("strategy must not be null");
        }
        strategy_ = std::move(strategy);
    }
    std::vector<int> sort(const std::vector<int>& values) const { return strategy_->sort(values); }

private:
    std::unique_ptr<SortStrategy> strategy_;
};

void print(const std::vector<int>& values) {
    std::cout << "sorted:";
    for (const int value : values) {
        std::cout << ' ' << value;
    }
    std::cout << '\n';
}

int main() {
    const std::vector<int> input{3, 1, 2};
    Sorter sorter(std::make_unique<Ascending>());
    print(sorter.sort(input));
    sorter.set_strategy(std::make_unique<Descending>());
    print(sorter.sort(input));
}
