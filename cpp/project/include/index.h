#ifndef DEVBOX_CPP_PROJECT_INDEX_H
#define DEVBOX_CPP_PROJECT_INDEX_H

// L1-034-preprocessor: guard repeated inclusion; constants use constexpr, not macros.
#if __cplusplus < 202002L
#error "The index requires C++20"
#endif

#include <algorithm>
#include <concepts>
#include <cstddef>
#include <functional>
#include <limits>
#include <memory>
#include <optional>
#include <stdexcept>
#include <string>
#include <string_view>
#include <type_traits>
#include <unordered_map>
#include <utility>
#include <variant>
#include <vector>

// L1-027-namespaces
namespace devbox {
namespace detail {

// L1-008-template-basics L1-009-template-constraints: only appendable sequences.
template <typename Sequence, typename Value>
    requires std::same_as<typename Sequence::value_type, std::remove_cvref_t<Value>> &&
             requires(Sequence& sequence, Value&& value) {
                 { sequence.empty() } -> std::convertible_to<bool>;
                 { sequence.back() == value } -> std::convertible_to<bool>;
                 sequence.push_back(std::forward<Value>(value));
             }
void append_unique(Sequence& sequence, Value&& value) {
    if (sequence.empty() || sequence.back() != value) {
        sequence.push_back(std::forward<Value>(value));
    }
}

// L1-016-constexpr L1-032-numeric-overflow: check before unsigned addition.
template <std::unsigned_integral T> constexpr T checked_add(T left, T right) {
    if (right > std::numeric_limits<T>::max() - left) {
        throw std::overflow_error("index size overflow");
    }
    return left + right;
}

// L1-030-static-assert
static_assert(checked_add(std::size_t{2}, std::size_t{3}) == 5);

} // namespace detail

// L1-020-operator-overloading L1-018-initialization
struct LineRange {
    std::size_t first{1};
    std::size_t last{std::numeric_limits<std::size_t>::max()};

    bool operator==(const LineRange&) const = default;
    bool contains(std::size_t line) const noexcept { return first <= line && line <= last; }
};

// L1-022-inheritance-polymorphism L1-023-virtual-destructor
class LinePredicate {
public:
    virtual ~LinePredicate() = default;
    virtual bool accepts(std::size_t line, const std::string& text) const = 0;
};

class RangePredicate final : public LinePredicate {
public:
    explicit RangePredicate(LineRange range) : range_(range) {
        if (range.first == 0 || range.first > range.last) {
            throw std::invalid_argument("invalid one-based line range");
        }
    }
    bool accepts(std::size_t line, const std::string&) const override {
        return range_.contains(line);
    }

private:
    LineRange range_;
};

class InvertedIndex {
    struct Data {
        // L1-010-stl-containers L1-011-container-selection: keyed lookup and ordered scans.
        std::unordered_map<std::string, std::vector<std::size_t>> postings;
        std::vector<std::string> lines;
    };

public:
    // L1-021-enum-class: a failed rebuild retains the previous ready state.
    enum class State { empty, ready };
    enum class QueryError { invalid_word };

    // L1-007-smart-pointers: results share immutable storage without owning the index.
    class Match {
    public:
        const std::vector<std::size_t>& lines() const noexcept { return lines_; }
        const std::string& line(std::size_t number) const;

        // L1-006-perfect-forwarding L1-031-function-callbacks
        template <typename Callback>
            requires std::constructible_from<std::decay_t<Callback>, Callback&&> &&
                     std::invocable<std::decay_t<Callback>&, std::size_t, const std::string&>
        void for_each(Callback&& callback) const {
            auto visitor = std::forward<Callback>(callback);
            for (const auto number : lines_) {
                std::invoke(visitor, number, data_->lines.at(number - 1));
            }
        }

    private:
        friend class InvertedIndex;
        Match(std::shared_ptr<const Data> data, std::vector<std::size_t> lines)
            : data_(std::move(data)), lines_(std::move(lines)) {}
        std::shared_ptr<const Data> data_;
        std::vector<std::size_t> lines_;
    };

    // L1-028-optional-variant: invalid input, no match and owned hits are distinct.
    using QueryResult = std::variant<QueryError, std::monostate, Match>;

    // L1-003-lifetime-copy-control L1-035-noexcept: copies share a snapshot;
    // rebuilding either copy replaces only its own snapshot, moves leave an empty index.
    InvertedIndex() = default;
    InvertedIndex(const InvertedIndex&) = default;
    InvertedIndex& operator=(const InvertedIndex&) = default;
    InvertedIndex(InvertedIndex&&) noexcept = default;
    InvertedIndex& operator=(InvertedIndex&&) noexcept = default;
    ~InvertedIndex() = default;

    bool build(const std::string& path);
    // L1-001-references-pointers L1-002-const-correctness L1-019-overload-resolution
    const std::vector<std::size_t>* find(const std::string& query) const;
    const std::vector<std::size_t>* find(std::string_view query) const;
    const std::vector<std::size_t>* find(const char* query) const;
    const std::string& line(std::size_t one_based_line) const;
    QueryResult query(std::string_view word, const LinePredicate* predicate = nullptr) const;
    std::optional<std::size_t> frequency(std::string_view word) const;
    std::pair<std::size_t, std::size_t> statistics() const;
    State state() const noexcept { return data_ ? State::ready : State::empty; }

private:
    std::shared_ptr<const Data> data_;
};

static_assert(std::is_nothrow_move_constructible_v<InvertedIndex>);
static_assert(std::is_nothrow_move_assignable_v<InvertedIndex>);

} // namespace devbox

#endif
