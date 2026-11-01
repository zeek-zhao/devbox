#include "index.h"

#include <array>
#include <cerrno>
#include <condition_variable>
#include <cstddef>
#include <cstring>
#include <cstdint>
#include <exception>
#include <fcntl.h>
#include <fstream>
#include <iterator>
#include <string>
#include <thread>
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
            error_ = "open '" + path + "': " + std::strerror(errno);
            return;
        }

        struct stat status {};
        // L1-032-numeric-overflow L1-026-explicit-casts
        if (fstat(descriptor_, &status) == -1 || !std::in_range<std::size_t>(status.st_size)) {
            close_descriptor();
            error_ = "stat/size '" + path + "': invalid file size or stat failure";
            return;
        }
        if (!S_ISREG(status.st_mode)) {
            close_descriptor();
            error_ = "map '" + path + "': not a regular file";
            return;
        }

        size_ = static_cast<std::size_t>(status.st_size);
        if (size_ == 0) {
            valid_ = true;
            return;
        }

        void* mapping = mmap(nullptr, size_, PROT_READ, MAP_PRIVATE, descriptor_, 0);
        if (mapping == MAP_FAILED) {
            const auto error = errno;
            close_descriptor();
            error_ = "mmap '" + path + "': " + std::strerror(error);
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
    const std::string& error() const noexcept { return error_; }

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
    std::string error_;
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

IndexConfig& IndexConfig::instance() {
    static IndexConfig config;
    return config;
}
void IndexConfig::workers(std::size_t value) {
    if (value == 0 || value > 64) {
        throw std::invalid_argument("worker count must be in [1,64]");
    }
    workers_.store(value, std::memory_order_relaxed);
}

std::shared_ptr<const std::string> TokenPool::intern(std::string word) {
    auto found = words_.find(word);
    if (found != words_.end()) {
        return found->second;
    }
    auto token = std::make_shared<const std::string>(std::move(word));
    words_.emplace(*token, token);
    return token;
}

namespace {
class TextParser final : public TokenParser {
public:
    std::vector<std::shared_ptr<const std::string>> parse(std::string_view text,
                                                          TokenPool& pool) const override {
        std::vector<std::shared_ptr<const std::string>> result;
        for_each_token(text,
                       [&](std::string token) { result.push_back(pool.intern(std::move(token))); });
        return result;
    }
};
class TsvParser final : public TokenParser {
public:
    std::vector<std::shared_ptr<const std::string>> parse(std::string_view text,
                                                          TokenPool& pool) const override {
        TextParser parser;
        std::vector<std::shared_ptr<const std::string>> result;
        // TSV's first column is a document key, not searchable content.
        if (const auto tab = text.find('\t'); tab != std::string_view::npos) {
            text.remove_prefix(tab + 1);
        }
        while (true) {
            const auto tab = text.find('\t');
            auto column = parser.parse(text.substr(0, tab), pool);
            result.insert(result.end(), column.begin(), column.end());
            if (tab == std::string_view::npos) {
                return result;
            }
            text.remove_prefix(tab + 1);
        }
    }
};
} // namespace

std::unique_ptr<TokenParser> TextParserFactory::create() const {
    return std::make_unique<TextParser>();
}
std::unique_ptr<TokenParser> TsvParserFactory::create() const {
    return std::make_unique<TsvParser>();
}

bool InvertedIndex::build(const std::string& path) {
    return build(path, IndexConfig::instance().workers(), TextParserFactory{});
}

// L2-004-file-io L2-011-error-reporting L3-001-mmap-files
bool InvertedIndex::build(const std::string& path, std::size_t workers,
                          const ParserFactory& factory) {
    if (workers == 0 || workers > 64) {
        throw std::invalid_argument("worker count must be in [1,64]");
    }
    MappedFile file(path);
    if (!file.valid()) {
        last_error_ = file.error();
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
        // L1-013-string-view L1-025-undefined-behavior: slice only a nonempty mapping,
        // and copy retained text before mmap ownership leaves this scope.
        const std::string_view text(file.data() + line_start, offset - line_start);
        next->lines.emplace_back(text);
        if (offset < file.size()) {
            ++offset;
        }
    }

    using Postings = decltype(next->postings);
    const auto count = std::min(workers, std::max(std::size_t{1}, next->lines.size()));
    std::vector<Postings> shards(count);
    auto create_parser = [&factory] {
        auto parser = factory.create();
        if (!parser) {
            throw std::runtime_error("parser factory returned null");
        }
        return parser;
    };
    auto parse_line = [&](Postings& shard, TokenParser& parser, TokenPool& pool,
                          std::size_t offset) {
        // L1-014-lambda-captures: all borrowed storage outlives joined workers.
        const auto number = detail::checked_add(offset, std::size_t{1});
        for (const auto& token : parser.parse(next->lines.at(offset), pool)) {
            if (!token) {
                throw std::runtime_error("parser returned null token");
            }
            detail::append_unique(shard[*token], number);
        }
    };
    auto merge_shards = [&] {
        for (auto& shard : shards) {
            for (auto& [word, lines] : shard) {
                auto& destination = next->postings[word];
                destination.insert(destination.end(), lines.begin(), lines.end());
            }
        }
        for (auto& [word, lines] : next->postings) {
            std::sort(lines.begin(), lines.end());
        }
    };
    if (count == 1) {
        auto parser = create_parser();
        TokenPool pool;
        for (std::size_t line = 0; line < next->lines.size(); ++line) {
            parse_line(shards[0], *parser, pool, line);
        }
        merge_shards();
    } else {
        // L3-002-thread-synchronization: stop-aware predicate wait and per-worker shards.
        std::mutex mutex;
        std::condition_variable_any gate;
        bool started = false;
        std::exception_ptr failure;
        std::atomic<std::size_t> next_line{0};
        // L3-003-atomics-memory-order: acquire observes all published shards before
        // readers merge them, BEFORE join. Relaxed only allocates unique line IDs.
        std::atomic<std::size_t> completed{0};
        {
            std::vector<std::jthread> threads;
            for (std::size_t worker = 0; worker < count; ++worker) {
                threads.emplace_back([&, worker](std::stop_token stop) {
                    std::unique_lock lock(mutex);
                    if (!gate.wait(lock, stop, [&] { return started; })) {
                        return;
                    }
                    lock.unlock();
                    try {
                        auto parser = create_parser();
                        TokenPool pool;
                        for (;;) {
                            const auto line = next_line.fetch_add(1, std::memory_order_relaxed);
                            if (line >= next->lines.size()) {
                                break;
                            }
                            parse_line(shards[worker], *parser, pool, line);
                        }
                    } catch (...) {
                        // Transport worker exceptions to the caller, never turn failure into
                        // success.
                        std::lock_guard guard(mutex);
                        if (!failure) {
                            failure = std::current_exception();
                        }
                    }
                    completed.fetch_add(1, std::memory_order_release);
                    completed.notify_one();
                });
            }
            {
                std::lock_guard guard(mutex);
                started = true;
            }
            gate.notify_all();
            auto observed = completed.load(std::memory_order_acquire);
            while (observed != count) {
                completed.wait(observed, std::memory_order_acquire);
                observed = completed.load(std::memory_order_acquire);
            }
            if (failure) {
                std::rethrow_exception(failure);
            }
            merge_shards();
        }
    }
    // L1-005-move-semantics: transfer the completed buffers' ownership, not their contents.
    data_ = std::move(next);
    last_error_.clear();
    return true;
}

namespace {
void write_u64(std::ostream& output, std::uint64_t value) {
    for (unsigned shift = 0; shift < 64; shift += 8) {
        output.put(static_cast<char>((value >> shift) & 255U));
    }
}
std::uint64_t read_u64(std::istream& input) {
    std::uint64_t result = 0;
    for (unsigned shift = 0; shift < 64; shift += 8) {
        const int byte = input.get();
        if (byte == std::char_traits<char>::eof()) {
            throw std::runtime_error("truncated index integer");
        }
        result |= static_cast<std::uint64_t>(static_cast<unsigned char>(byte)) << shift;
    }
    return result;
}
} // namespace

void InvertedIndex::save(const std::string& path) const {
    if (!data_) {
        throw std::logic_error("cannot serialize an unbuilt index");
    }
    try {
        std::ofstream output(path, std::ios::binary | std::ios::trunc);
        output.exceptions(std::ios::failbit | std::ios::badbit);
        output.write("DBIX\1\0\0\0", 8);
        write_u64(output, data_->lines.size());
        for (const auto& text : data_->lines) {
            if (!std::in_range<std::streamsize>(text.size())) {
                throw std::overflow_error("index record exceeds stream size");
            }
            write_u64(output, text.size());
            output.write(text.data(), static_cast<std::streamsize>(text.size()));
        }
        const auto words = terms();
        write_u64(output, words.size());
        for (const auto& word : words) {
            write_u64(output, word.size());
            output.write(word.data(), static_cast<std::streamsize>(word.size()));
            const auto& postings = data_->postings.at(word);
            write_u64(output, postings.size());
            for (auto number : postings) {
                write_u64(output, number);
            }
        }
        output.close();
    } catch (const std::ios_base::failure& error) {
        throw std::runtime_error("write index '" + path + "': " + error.what());
    }
}

void InvertedIndex::load(const std::string& path) {
    std::ifstream input(path, std::ios::binary | std::ios::ate);
    if (!input) {
        throw std::runtime_error("open index '" + path + "': failed");
    }
    const auto end = input.tellg();
    if (end < 16) {
        throw std::runtime_error("truncated index header: " + path);
    }
    auto remaining = static_cast<std::uint64_t>(end) - 16;
    input.seekg(0);
    std::array<char, 8> header{};
    input.read(header.data(), header.size());
    if (std::string_view(header.data(), header.size()) != std::string_view("DBIX\1\0\0\0", 8)) {
        throw std::runtime_error("invalid index magic/version: " + path);
    }
    const auto count = read_u64(input);
    if (count > remaining / 8) {
        throw std::runtime_error("invalid index record count: " + path);
    }
    auto next = std::make_shared<Data>();
    for (std::uint64_t number = 0; number < count; ++number) {
        if (remaining < 8) {
            throw std::runtime_error("truncated index record header: " + path);
        }
        const auto length = read_u64(input);
        remaining -= 8;
        if (length > remaining || !std::in_range<std::size_t>(length) ||
            !std::in_range<std::streamsize>(length)) {
            throw std::runtime_error("invalid index record length: " + path);
        }
        std::string text(static_cast<std::size_t>(length), '\0');
        input.read(text.data(), static_cast<std::streamsize>(length));
        if (!input || text.find('\n') != std::string::npos) {
            throw std::runtime_error("invalid/truncated index record: " + path);
        }
        remaining -= length;
        next->lines.push_back(std::move(text));
    }
    auto integer = [&] {
        if (remaining < 8) {
            throw std::runtime_error("truncated index dictionary: " + path);
        }
        remaining -= 8;
        return read_u64(input);
    };
    const auto words = integer();
    if (words > remaining / 25) {
        throw std::runtime_error("invalid index dictionary count: " + path);
    }
    std::string previous;
    for (std::uint64_t i = 0; i < words; ++i) {
        const auto length = integer();
        if (length == 0 || length > remaining || !std::in_range<std::streamsize>(length) ||
            !std::in_range<std::size_t>(length)) {
            throw std::runtime_error("invalid index word length: " + path);
        }
        std::string word(static_cast<std::size_t>(length), '\0');
        input.read(word.data(), static_cast<std::streamsize>(length));
        remaining -= length;
        const auto normalized = normalize_word(word);
        if (!input || !normalized || *normalized != word || word <= previous) {
            throw std::runtime_error("invalid/unsorted index word: " + path);
        }
        previous = word;
        const auto entries = integer();
        if (entries == 0 || entries > next->lines.size() || entries > remaining / 8) {
            throw std::runtime_error("invalid index posting count: " + path);
        }
        auto& postings = next->postings[word];
        for (std::uint64_t entry = 0; entry < entries; ++entry) {
            const auto number = integer();
            if (number == 0 || number > next->lines.size() ||
                (!postings.empty() && number <= postings.back())) {
                throw std::runtime_error("invalid/unsorted index posting: " + path);
            }
            postings.push_back(static_cast<std::size_t>(number));
        }
    }
    if (remaining != 0) {
        throw std::runtime_error("trailing index bytes: " + path);
    }
    data_ = std::move(next);
    last_error_.clear();
}

std::vector<std::string> InvertedIndex::terms() const {
    std::vector<std::string> result;
    if (data_) {
        result.reserve(data_->postings.size());
        for (const auto& [word, lines] : data_->postings) {
            result.push_back(word);
        }
        std::sort(result.begin(), result.end());
    }
    return result;
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
