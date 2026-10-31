#include "index.h"
#include "index.h"

#include <array>
#include <cassert>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <memory>
#include <new>
#include <string>
#include <unistd.h>
#include <vector>

namespace {
thread_local bool fail_next_allocation{false};
}

// Test-only failure injection exercises rollback after mmap succeeds.
void* operator new(std::size_t size) {
    if (std::exchange(fail_next_allocation, false)) {
        throw std::bad_alloc{};
    }
    if (void* allocation = std::malloc(size == 0 ? 1 : size)) {
        return allocation;
    }
    throw std::bad_alloc{};
}

void operator delete(void* allocation) noexcept {
    std::free(allocation);
}
void operator delete(void* allocation, std::size_t) noexcept {
    std::free(allocation);
}

namespace {

class TemporaryFile {
public:
    TemporaryFile() {
        auto name = (std::filesystem::temp_directory_path() / "devbox-index-test-XXXXXX").string();
        const int descriptor = mkstemp(name.data());
        if (descriptor == -1) {
            throw std::runtime_error("cannot create test file");
        }
        close(descriptor);
        path = name;
    }
    ~TemporaryFile() { std::filesystem::remove(path); }
    TemporaryFile(const TemporaryFile&) = delete;
    TemporaryFile& operator=(const TemporaryFile&) = delete;

    void write(const std::string& text) const {
        std::ofstream output(path, std::ios::binary | std::ios::trunc);
        output.exceptions(std::ios::failbit | std::ios::badbit);
        output << text;
    }
    std::filesystem::path path;
};

template <typename Exception, typename Callback> void expect_throw(Callback callback) {
    bool thrown = false;
    try {
        callback();
    } catch (const Exception&) {
        thrown = true;
    }
    assert(thrown);
}

using Index = devbox::InvertedIndex;

// L1-009-template-constraints: unsuitable containers/callbacks are rejected at deduction.
template <typename Sequence, typename Value>
concept CanAppend = requires(Sequence& sequence, Value&& value) {
    devbox::detail::append_unique(sequence, std::forward<Value>(value));
};
template <typename Callback>
concept CanVisit = requires(const Index::Match& match, Callback&& callback) {
    match.for_each(std::forward<Callback>(callback));
};
static_assert(CanAppend<std::vector<std::size_t>, std::size_t>);
static_assert(!CanAppend<std::vector<std::size_t>, std::string>);
static_assert(!CanAppend<std::array<std::size_t, 2>, std::size_t>);
static_assert(!CanVisit<int>);
static_assert(!std::is_convertible_v<Index::State, int>);
static_assert(std::is_same_v<decltype(std::declval<const Index&>().line(1)), const std::string&>);

struct Visitor {
    int& copies;
    int& moves;
    std::size_t& calls;
    Visitor(int& copies, int& moves, std::size_t& calls)
        : copies(copies), moves(moves), calls(calls) {}
    Visitor(const Visitor& other) : copies(other.copies), moves(other.moves), calls(other.calls) {
        ++copies;
    }
    Visitor(Visitor&& other) noexcept
        : copies(other.copies), moves(other.moves), calls(other.calls) {
        ++moves;
    }
    void operator()(std::size_t, const std::string&) { ++calls; }
};

// The weak observer does not keep the resource alive after base-pointer destruction.
class OwningPredicate final : public devbox::LinePredicate {
public:
    explicit OwningPredicate(std::shared_ptr<int> resource) : resource_(std::move(resource)) {}
    bool accepts(std::size_t, const std::string&) const override { return *resource_ == 7; }

private:
    std::shared_ptr<int> resource_;
};

class ThrowingPredicate final : public devbox::LinePredicate {
public:
    bool accepts(std::size_t, const std::string&) const override {
        throw std::runtime_error("predicate failed");
    }
};

std::size_t callback_calls{0};
void count_match(std::size_t, const std::string&) {
    ++callback_calls;
}

} // namespace

int main() {
    TemporaryFile file;
    file.write("Alpha beta alpha\ngamma, ALPHA\ndelta\n");
    devbox::InvertedIndex index;
    assert(index.state() == Index::State::empty);
    assert(index.find("alpha") == nullptr);
    expect_throw<std::out_of_range>([&] { index.line(1); });
    assert(index.build(file.path.string()));
    assert(index.state() == Index::State::ready);

    const auto& readonly = index;
    const auto* alpha = index.find("alpha");
    assert(alpha != nullptr);
    assert((*alpha == std::vector<std::size_t>{1, 2}));
    assert(readonly.line(1) == "Alpha beta alpha");
    const std::string owned_query{"ALPHA"};
    assert(readonly.find(owned_query) == alpha);
    const std::string padded{"!ALPHA!"};
    assert(readonly.find(std::string_view(padded).substr(1, 5)) == alpha);
    assert(readonly.find(static_cast<const char*>(nullptr)) == nullptr);

    const auto* beta = index.find("BETA");
    assert(beta != nullptr);
    assert((*beta == std::vector<std::size_t>{1}));
    assert(index.find("missing") == nullptr);
    assert(index.find("alpha!") == nullptr);
    assert(index.find("") == nullptr);
    expect_throw<std::out_of_range>([&] { index.line(0); });
    expect_throw<std::out_of_range>([&] { index.line(4); });

    assert(std::holds_alternative<Index::QueryError>(index.query("alpha!")));
    assert(std::get<Index::QueryError>(index.query("")) == Index::QueryError::invalid_word);
    assert(std::holds_alternative<std::monostate>(index.query("missing")));
    assert(index.frequency("alpha") == std::optional<std::size_t>{2});
    assert(!index.frequency("missing"));
    assert(!index.frequency("!"));
    const auto [terms, entries] = index.statistics();
    assert(terms == 4 && entries == 5);

    const devbox::LineRange range{2, 2};
    assert((range == devbox::LineRange{2, 2}));
    assert(!(range == devbox::LineRange{1, 2}));
    devbox::RangePredicate predicate(range);
    const devbox::LinePredicate& base = predicate;
    assert(base.accepts(2, "") && !base.accepts(1, ""));
    auto filtered = index.query("alpha", &base);
    assert((std::get<Index::Match>(filtered).lines() == std::vector<std::size_t>{2}));
    assert(std::get<Index::Match>(filtered).line(2) == "gamma, ALPHA");
    expect_throw<std::out_of_range>([&] { std::get<Index::Match>(filtered).line(1); });
    devbox::RangePredicate excluded(devbox::LineRange{3, 3});
    assert(std::holds_alternative<std::monostate>(index.query("alpha", &excluded)));
    expect_throw<std::invalid_argument>([] { devbox::RangePredicate bad({0, 1}); });
    expect_throw<std::invalid_argument>([] { devbox::RangePredicate bad({2, 1}); });

    auto result = index.query("alpha");
    const auto& match = std::get<Index::Match>(result);
    int copies{0}, moves{0};
    std::size_t calls{0};
    Visitor visitor(copies, moves, calls);
    match.for_each(visitor);
    assert(copies == 1 && moves == 0 && calls == 2);
    match.for_each(std::move(visitor));
    assert(copies == 1 && moves == 1 && calls == 4);
    match.for_each(count_match);
    assert(callback_calls == 2);
    match.for_each(+[](std::size_t, const std::string&) { ++callback_calls; });
    assert(callback_calls == 4);
    auto counter = std::make_unique<std::size_t>(0);
    auto* counter_view = counter.get();
    auto move_only = [counter = std::move(counter)](std::size_t, const std::string&) {
        ++*counter;
    };
    match.for_each([&](std::size_t number, const std::string& text) {
        move_only(number, text);
        assert(*counter_view <= 2);
    });
    assert(*counter_view == 2);
    match.for_each(std::move(move_only));

    std::weak_ptr<int> observer;
    {
        auto resource = std::make_shared<int>(7);
        observer = resource;
        std::unique_ptr<devbox::LinePredicate> owned =
            std::make_unique<OwningPredicate>(std::move(resource));
        assert(std::holds_alternative<Index::Match>(index.query("alpha", owned.get())));
        assert(!observer.expired());
    }
    assert(observer.expired());

    ThrowingPredicate throwing;
    expect_throw<std::runtime_error>([&] { index.query("alpha", &throwing); });
    expect_throw<std::runtime_error>([&] {
        match.for_each(
            [](std::size_t, const std::string&) { throw std::runtime_error("callback failed"); });
    });
    assert(index.find("alpha") == alpha);

    auto copy = index;
    Index assigned;
    assigned = copy;
    assert(copy.find("alpha") == alpha && assigned.find("alpha") == alpha);
    auto moved = std::move(copy);
    assert(copy.state() == Index::State::empty && copy.find("alpha") == nullptr);
    copy = std::move(assigned);
    assert(assigned.state() == Index::State::empty);
    assert(copy.find("alpha") == alpha && moved.find("alpha") == alpha);
    assert(!index.build((file.path / "missing").string()));
    assert(index.find("alpha") == alpha && index.state() == Index::State::ready);
    const auto build_path = file.path.string();
    fail_next_allocation = true;
    expect_throw<std::bad_alloc>([&] { index.build(build_path); });
    assert(!fail_next_allocation);
    assert(index.find("alpha") == alpha && index.line(1) == "Alpha beta alpha");

    file.write("");
    assert(index.build(file.path.string()));
    assert(index.state() == Index::State::ready && index.find("alpha") == nullptr);
    assert((index.statistics() == std::pair<std::size_t, std::size_t>{0, 0}));
    expect_throw<std::out_of_range>([&] { index.line(1); });
    assert(match.line(1) == "Alpha beta alpha");
    assert(moved.line(2) == "gamma, ALPHA");
    file.write("reused");
    assert(copy.build(file.path.string()));
    assert(copy.find("reused") != nullptr && moved.find("reused") == nullptr);
    moved = Index{};
    result = std::monostate{};
    // The independently filtered result still owns the old text.
    assert(std::get<Index::Match>(filtered).line(2) == "gamma, ALPHA");

    // L1-025-undefined-behavior: empty lines, final non-newline text and non-ASCII bytes.
    const std::string short_word(64, 'A');
    const std::string long_word(65, 'B');
    const std::string binary{"one\0two\xff!", 9};
    file.write("\n" + short_word + " " + long_word + "\r\n" + binary);
    assert(index.build(file.path.string()));
    assert(index.line(1).empty());
    assert(((*index.find(short_word)) == std::vector<std::size_t>{2}));
    assert(((*index.find(long_word)) == std::vector<std::size_t>{2}));
    assert(((*index.find("two")) == std::vector<std::size_t>{3}));
    assert(index.find(std::string_view(binary)) == nullptr);

    std::vector<std::size_t> numbers;
    devbox::detail::append_unique(numbers, std::size_t{1});
    devbox::detail::append_unique(numbers, std::size_t{1});
    // No pointer/iterator into the vector is retained across growth.
    for (std::size_t number = 2; number <= 1000; ++number) {
        devbox::detail::append_unique(numbers, number);
    }
    assert(numbers.size() == 1000 && numbers.back() == 1000);
    std::vector<std::string> words;
    std::string term{"alpha"};
    devbox::detail::append_unique(words, term);
    devbox::detail::append_unique(words, std::string{"alpha"});
    devbox::detail::append_unique(words, std::string{"beta"});
    assert((words == std::vector<std::string>{"alpha", "beta"}));
    constexpr auto maximum = std::numeric_limits<std::size_t>::max();
    assert(devbox::detail::checked_add(maximum, std::size_t{0}) == maximum);
    expect_throw<std::overflow_error>(
        [&] { devbox::detail::checked_add(maximum, std::size_t{1}); });
    return 0;
}
