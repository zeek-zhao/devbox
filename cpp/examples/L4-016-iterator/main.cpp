#include <cstddef>
#include <initializer_list>
#include <iostream>
#include <iterator>
#include <stdexcept>
#include <vector>

class Sequence {
public:
    class Iterator {
    public:
        using iterator_category = std::forward_iterator_tag;
        using value_type = int;
        using difference_type = std::ptrdiff_t;
        using pointer = const int*;
        using reference = const int&;

        Iterator() = default;
        reference operator*() const {
            if (!owner_ || position_ >= owner_->values_.size()) {
                throw std::out_of_range("iterator exhausted");
            }
            return owner_->values_[position_];
        }
        pointer operator->() const { return &operator*(); }
        Iterator& operator++() {
            if (!owner_ || position_ >= owner_->values_.size()) {
                throw std::out_of_range("iterator exhausted");
            }
            ++position_;
            return *this;
        }
        Iterator operator++(int) {
            auto previous = *this;
            ++*this;
            return previous;
        }
        bool operator==(const Iterator&) const = default;

    private:
        friend class Sequence;
        Iterator(const Sequence* owner, std::size_t position)
            : owner_(owner), position_(position) {}
        const Sequence* owner_ = nullptr;
        std::size_t position_ = 0;
    };

    Sequence(std::initializer_list<int> values) : values_(values) {}
    Iterator begin() const { return Iterator(this, 0); }
    Iterator end() const { return Iterator(this, values_.size()); }

private:
    std::vector<int> values_;
};

static_assert(std::forward_iterator<Sequence::Iterator>);

int main() {
    const Sequence sequence{2, 4, 6};
    std::cout << "range:";
    for (const int value : sequence) {
        std::cout << ' ' << value;
    }
    std::cout << '\n';

    auto iterator = sequence.begin();
    while (iterator != sequence.end()) {
        ++iterator;
    }
    std::cout << std::boolalpha
              << "exhausted equals end: " << (iterator == sequence.end()) << '\n';
    try {
        std::cout << *iterator << '\n';
        return 1;
    } catch (const std::out_of_range& error) {
        std::cout << "error: " << error.what() << '\n';
    }
}
