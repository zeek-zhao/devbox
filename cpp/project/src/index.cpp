#include "index.h"

#include <array>
#include <cstddef>
#include <fcntl.h>
#include <iterator>
#include <string>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>
#include <utility>

namespace devbox {
namespace {

class MappedFile {
public:
    explicit MappedFile(const std::string& path) {
        descriptor_ = open(path.c_str(), O_RDONLY);
        if (descriptor_ == -1) {
            return;
        }

        struct stat status {};
        // L1-032-numeric-overflow L1-026-explicit-casts
        if (fstat(descriptor_, &status) == -1 || !std::in_range<std::size_t>(status.st_size)) {
            close_descriptor();
            return;
        }

        size_ = static_cast<std::size_t>(status.st_size);
        if (size_ == 0) {
            valid_ = true;
            return;
        }

        void* mapping = mmap(nullptr, size_, PROT_READ, MAP_PRIVATE, descriptor_, 0);
        if (mapping == MAP_FAILED) {
            close_descriptor();
            size_ = 0;
            return;
        }
        data_ = static_cast<char*>(mapping);
        valid_ = true;
    }

    MappedFile(const MappedFile&) = delete;
    MappedFile& operator=(const MappedFile&) = delete;

    // L1-004-raii: also releases the mapping during exception unwinding.
    ~MappedFile() { release(); }

    bool valid() const noexcept { return valid_; }
    const char* data() const noexcept { return data_; }
    std::size_t size() const noexcept { return size_; }

private:
    void release() noexcept {
        if (data_ != nullptr) {
            munmap(data_, size_);
            data_ = nullptr;
        }
        close_descriptor();
        size_ = 0;
        valid_ = false;
    }

    void close_descriptor() noexcept {
        if (descriptor_ != -1) {
            close(descriptor_);
            descriptor_ = -1;
        }
    }

    int descriptor_ = -1;
    char* data_ = nullptr;
    std::size_t size_ = 0;
    bool valid_ = false;
};

constexpr bool is_word_character(unsigned char character) noexcept {
    return (character >= 'a' && character <= 'z') || (character >= 'A' && character <= 'Z') ||
           (character >= '0' && character <= '9');
}

constexpr char lowercase_ascii(unsigned char character) noexcept {
    if (character >= 'A' && character <= 'Z') {
        return static_cast<char>(character - 'A' + 'a');
    }
    return static_cast<char>(character);
}

// L1-033-array-types: short queries use a fixed, length-aware stack buffer.
constexpr std::size_t query_buffer_size{64};
static_assert(query_buffer_size > 0);

std::optional<std::string> normalize_word(std::string_view word) {
    if (word.empty()) {
        return std::nullopt;
    }
    std::array<char, query_buffer_size> buffer{};
    std::string normalized;
    if (word.size() > buffer.size()) {
        normalized.reserve(word.size());
    }
    for (std::size_t offset = 0; offset < word.size(); ++offset) {
        const auto character = static_cast<unsigned char>(word[offset]);
        if (!is_word_character(character)) {
            return std::nullopt;
        }
        const char lower = lowercase_ascii(character);
        if (word.size() <= buffer.size()) {
            buffer.at(offset) = lower;
        } else {
            normalized.push_back(lower);
        }
    }
    if (word.size() <= buffer.size()) {
        return std::string(buffer.data(), word.size());
    }
    return normalized;
}

template <typename Callback> void for_each_token(std::string_view text, Callback&& callback) {
    std::size_t offset = 0;
    while (offset < text.size()) {
        while (offset < text.size() &&
               !is_word_character(static_cast<unsigned char>(text[offset]))) {
            ++offset;
        }

        const std::size_t start = offset;
        while (offset < text.size() &&
               is_word_character(static_cast<unsigned char>(text[offset]))) {
            ++offset;
        }
        if (start != offset) {
            std::string token;
            token.reserve(offset - start);
            for (std::size_t index = start; index < offset; ++index) {
                token.push_back(lowercase_ascii(static_cast<unsigned char>(text[index])));
            }
            callback(std::move(token));
        }
    }
}

} // namespace

bool InvertedIndex::build(const std::string& path) {
    MappedFile file(path);
    if (!file.valid()) {
        return false;
    }

    // L1-024-exception-safety: publish only after all allocations and parsing succeed.
    auto next = std::make_shared<Data>();
    std::size_t offset = 0;

    while (offset < file.size()) {
        const std::size_t line_start = offset;
        while (offset < file.size() && file.data()[offset] != '\n') {
            ++offset;
        }
        const std::size_t line_number = detail::checked_add(next->lines.size(), std::size_t{1});
        // L1-013-string-view L1-025-undefined-behavior: slice only a nonempty mapping,
        // and copy retained text before mmap ownership leaves this scope.
        const std::string_view text(file.data() + line_start, offset - line_start);
        next->lines.emplace_back(text);
        // L1-014-lambda-captures: synchronous reference capture, line number by value.
        for_each_token(text, [&next, line_number](std::string token) {
            auto& postings = next->postings[std::move(token)];
            detail::append_unique(postings, line_number);
        });
        if (offset < file.size()) {
            ++offset;
        }
    }

    // L1-005-move-semantics: transfer the completed buffers' ownership, not their contents.
    data_ = std::move(next);
    return true;
}

const std::vector<std::size_t>* InvertedIndex::find(const std::string& query) const {
    return find(std::string_view(query));
}

const std::vector<std::size_t>* InvertedIndex::find(const char* query) const {
    return query == nullptr ? nullptr : find(std::string_view(query));
}

const std::vector<std::size_t>* InvertedIndex::find(std::string_view query) const {
    const auto normalized = normalize_word(query);
    if (!normalized || !data_) {
        return nullptr;
    }
    const auto found = data_->postings.find(*normalized);
    return found == data_->postings.end() ? nullptr : &found->second;
}

const std::string& InvertedIndex::line(std::size_t one_based_line) const {
    if (!data_ || one_based_line == 0) {
        throw std::out_of_range("invalid one-based line number");
    }
    return data_->lines.at(one_based_line - 1);
}

const std::string& InvertedIndex::Match::line(std::size_t number) const {
    // L1-012-iterators-algorithms: postings are sorted; no iterator survives mutation.
    if (!std::binary_search(lines_.begin(), lines_.end(), number)) {
        throw std::out_of_range("line is not in query results");
    }
    return data_->lines.at(number - 1);
}

InvertedIndex::QueryResult InvertedIndex::query(std::string_view word,
                                                const LinePredicate* predicate) const {
    const auto normalized = normalize_word(word);
    if (!normalized) {
        return QueryError::invalid_word;
    }
    const auto snapshot = data_;
    if (!snapshot) {
        return std::monostate{};
    }
    const auto found = snapshot->postings.find(*normalized);
    if (found == snapshot->postings.end()) {
        return std::monostate{};
    }
    std::vector<std::size_t> selected;
    // L1-015-type-deduction: const auto& preserves the original postings, no copy.
    const auto& postings = found->second;
    selected.reserve(postings.size());
    std::copy_if(postings.begin(), postings.end(), std::back_inserter(selected),
                 [&snapshot, predicate](std::size_t number) {
                     return predicate == nullptr ||
                            predicate->accepts(number, snapshot->lines.at(number - 1));
                 });
    if (selected.empty()) {
        return std::monostate{};
    }
    return Match(snapshot, std::move(selected));
}

std::optional<std::size_t> InvertedIndex::frequency(std::string_view word) const {
    const auto* postings = find(word);
    return postings == nullptr ? std::nullopt : std::optional{postings->size()};
}

std::pair<std::size_t, std::size_t> InvertedIndex::statistics() const {
    std::size_t entries{0};
    if (!data_) {
        return {0, 0};
    }
    // L1-017-structured-bindings L1-029-pair-tuple: references avoid copying lists.
    for (const auto& [term, postings] : data_->postings) {
        entries = detail::checked_add(entries, postings.size());
    }
    return {data_->postings.size(), entries};
}

} // namespace devbox
