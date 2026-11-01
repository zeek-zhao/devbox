#ifndef DEVBOX_CPP_PROJECT_INDEX_H
#define DEVBOX_CPP_PROJECT_INDEX_H

// L1-034-preprocessor: guard repeated inclusion; constants use constexpr, not macros.
#if __cplusplus < 202002L
#error "The index requires C++20"
#endif

#include <algorithm>
#include <atomic>
#include <concepts>
#include <cstddef>
#include <functional>
#include <iosfwd>
#include <iterator>
#include <limits>
#include <memory>
#include <mutex>
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

// L4-001-singleton: one configuration entrance, safe even before worker startup.
class IndexConfig {
public:
    static IndexConfig& instance();
    IndexConfig(const IndexConfig&) = delete;
    IndexConfig& operator=(const IndexConfig&) = delete;
    void workers(std::size_t value);
    std::size_t workers() const noexcept { return workers_.load(std::memory_order_relaxed); }

private:
    IndexConfig() = default;
    std::atomic<std::size_t> workers_{1};
};

// L4-011-flyweight: positions remain in postings, never in shared token objects.
class TokenPool {
public:
    std::shared_ptr<const std::string> intern(std::string word);
    std::size_t size() const noexcept { return words_.size(); }

private:
    std::unordered_map<std::string, std::shared_ptr<const std::string>> words_;
};

// L4-016-iterator: an owned vocabulary exposes traversal, not the postings representation.
class Vocabulary {
public:
    class Iterator {
    public:
        using iterator_category = std::forward_iterator_tag;
        using value_type = std::string;
        using difference_type = std::ptrdiff_t;
        using pointer = const std::string*;
        using reference = const std::string&;
        Iterator() = default;
        reference operator*() const { return *current_; }
        pointer operator->() const { return &*current_; }
        Iterator& operator++() {
            ++current_;
            return *this;
        }
        Iterator operator++(int) {
            auto before = *this;
            ++*this;
            return before;
        }
        bool operator==(const Iterator&) const = default;

    private:
        friend class Vocabulary;
        explicit Iterator(std::vector<std::string>::const_iterator current) : current_(current) {}
        std::vector<std::string>::const_iterator current_;
    };
    explicit Vocabulary(std::vector<std::string> words) : words_(std::move(words)) {}
    Iterator begin() const { return Iterator(words_.cbegin()); }
    Iterator end() const { return Iterator(words_.cend()); }

private:
    std::vector<std::string> words_;
};
static_assert(std::forward_iterator<Vocabulary::Iterator>);

class TokenParser {
public:
    virtual ~TokenParser() = default;
    virtual std::vector<std::shared_ptr<const std::string>> parse(std::string_view text,
                                                                  TokenPool& pool) const = 0;
};

// L4-002-factory-method: factories, not the caller, choose the input parser.
class ParserFactory {
public:
    virtual ~ParserFactory() = default;
    virtual std::unique_ptr<TokenParser> create() const = 0;
};
class TextParserFactory final : public ParserFactory {
public:
    std::unique_ptr<TokenParser> create() const override;
};
class TsvParserFactory final : public ParserFactory {
public:
    std::unique_ptr<TokenParser> create() const override;
};

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
        auto begin() const noexcept { return lines_.cbegin(); }
        auto end() const noexcept { return lines_.cend(); }
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
    bool build(const std::string& path, std::size_t workers, const ParserFactory& parser);
    const std::string& last_error() const noexcept { return last_error_; }
    // L3-005-binary-serialization: versioned little-endian text/postings, not native structs.
    void save(const std::string& path) const;
    void load(const std::string& path);
    // L4-018-memento: opaque immutable snapshots cannot be edited by caretakers.
    class Snapshot {
        friend class InvertedIndex;
        explicit Snapshot(std::shared_ptr<const Data> data) : data_(std::move(data)) {}
        std::shared_ptr<const Data> data_;
    };
    Snapshot checkpoint() const { return Snapshot(data_); }
    void restore(const Snapshot& snapshot) noexcept { data_ = snapshot.data_; }
    // L1-001-references-pointers L1-002-const-correctness L1-019-overload-resolution
    const std::vector<std::size_t>* find(const std::string& query) const;
    const std::vector<std::size_t>* find(std::string_view query) const;
    const std::vector<std::size_t>* find(const char* query) const;
    const std::string& line(std::size_t one_based_line) const;
    QueryResult query(std::string_view word, const LinePredicate* predicate = nullptr) const;
    std::optional<std::size_t> frequency(std::string_view word) const;
    std::pair<std::size_t, std::size_t> statistics() const;
    // L4-016-iterator: return an owned sorted vocabulary, no hash order or invalidation.
    std::vector<std::string> terms() const;
    Vocabulary vocabulary() const { return Vocabulary(terms()); }
    State state() const noexcept { return data_ ? State::ready : State::empty; }

private:
    std::shared_ptr<const Data> data_;
    std::string last_error_;
};

static_assert(std::is_nothrow_move_constructible_v<InvertedIndex>);
static_assert(std::is_nothrow_move_assignable_v<InvertedIndex>);

struct Hit {
    std::size_t number;
    std::string text;
    bool operator==(const Hit&) const = default;
};
using Hits = std::vector<Hit>;

class QuerySource {
public:
    virtual ~QuerySource() = default;
    virtual Hits lookup(std::string_view word) const = 0;
};

// L4-005-prototype: cloning reuses immutable built data, replacement is independent.
class IndexPrototype {
public:
    virtual ~IndexPrototype() = default;
    virtual std::unique_ptr<IndexPrototype> clone() const = 0;
    virtual void replace(InvertedIndex index) = 0;
    virtual const InvertedIndex& index() const = 0;
};
class SnapshotSource final : public QuerySource, public IndexPrototype {
public:
    explicit SnapshotSource(InvertedIndex index) : index_(std::move(index)) {}
    Hits lookup(std::string_view word) const override;
    std::unique_ptr<IndexPrototype> clone() const override;
    void replace(InvertedIndex index) override { index_ = std::move(index); }
    const InvertedIndex& index() const override { return index_; }

private:
    InvertedIndex index_;
};

// L4-006-adapter: delegate to the unchanged pointer-based find/line interface.
class LegacyQueryAdapter final : public QuerySource {
public:
    explicit LegacyQueryAdapter(InvertedIndex index) : index_(std::move(index)) {}
    Hits lookup(std::string_view word) const override;

private:
    InvertedIndex index_;
};

// L4-012-proxy: first lookup loads a binary index; concurrent readers load it once.
class LazyQuery final : public QuerySource {
public:
    explicit LazyQuery(std::string path) : path_(std::move(path)) {}
    Hits lookup(std::string_view word) const override;
    std::size_t calls() const noexcept { return calls_.load(std::memory_order_relaxed); }
    bool loaded() const;

private:
    std::string path_;
    mutable std::mutex mutex_;
    mutable std::unique_ptr<SnapshotSource> source_;
    mutable std::atomic<std::size_t> calls_{0};
};

class SnapshotStore {
public:
    virtual ~SnapshotStore() = default;
    virtual void write(const InvertedIndex& index) = 0;
    virtual InvertedIndex read() const = 0;
};

// L4-003-abstract-factory: paired products are created together, not assembled by clients.
class Backend {
public:
    const std::shared_ptr<QuerySource>& source() const { return source_; }
    SnapshotStore& store() const { return *store_; }

private:
    friend class MemoryBackendFactory;
    friend class LocalBackendFactory;
    Backend(std::shared_ptr<QuerySource> source, std::shared_ptr<SnapshotStore> store)
        : source_(std::move(source)), store_(std::move(store)) {}
    std::shared_ptr<QuerySource> source_;
    std::shared_ptr<SnapshotStore> store_;
};
class BackendFactory {
public:
    virtual ~BackendFactory() = default;
    virtual Backend create(InvertedIndex index) const = 0;
};
class MemoryBackendFactory final : public BackendFactory {
public:
    Backend create(InvertedIndex index) const override;
};
class LocalBackendFactory final : public BackendFactory {
public:
    explicit LocalBackendFactory(std::string path) : path_(std::move(path)) {}
    Backend create(InvertedIndex index) const override;

private:
    std::string path_;
};

class UpdateListener {
public:
    virtual ~UpdateListener() = default;
    virtual void updated() = 0;
};

// L4-009-decorator: query counting and caching are independently composable.
class CountingQuery final : public QuerySource {
public:
    explicit CountingQuery(std::shared_ptr<QuerySource> inner);
    Hits lookup(std::string_view word) const override;
    std::size_t calls() const noexcept { return calls_.load(std::memory_order_relaxed); }

private:
    std::shared_ptr<QuerySource> inner_;
    mutable std::atomic<std::size_t> calls_{0};
};
class CachedQuery final : public QuerySource, public UpdateListener {
public:
    explicit CachedQuery(std::shared_ptr<QuerySource> inner);
    Hits lookup(std::string_view word) const override;
    void updated() override;

private:
    std::shared_ptr<QuerySource> inner_;
    mutable std::unordered_map<std::string, Hits> cache_;
};

class TermExpression;
class AndExpression;
class OrExpression;
// L4-023-visitor: operations dispatch on concrete AST nodes, not type tests.
class ExpressionVisitor {
public:
    virtual ~ExpressionVisitor() = default;
    virtual void visit(const TermExpression&) = 0;
    virtual void visit(const AndExpression&) = 0;
    virtual void visit(const OrExpression&) = 0;
};
// L4-008-composite L4-015-interpreter: leaves and groups share the same evaluator.
class Expression {
public:
    virtual ~Expression() = default;
    virtual Hits evaluate(const QuerySource&) const = 0;
    virtual void accept(ExpressionVisitor&) const = 0;
};
class TermExpression final : public Expression {
public:
    explicit TermExpression(std::string word);
    const std::string& word() const { return word_; }
    Hits evaluate(const QuerySource&) const override;
    void accept(ExpressionVisitor& visitor) const override { visitor.visit(*this); }

private:
    std::string word_;
};
class GroupExpression : public Expression {
public:
    explicit GroupExpression(std::vector<std::shared_ptr<const Expression>> children);
    const auto& children() const { return children_; }

private:
    std::vector<std::shared_ptr<const Expression>> children_;
};
class AndExpression final : public GroupExpression {
public:
    using GroupExpression::GroupExpression;
    Hits evaluate(const QuerySource&) const override;
    void accept(ExpressionVisitor& visitor) const override { visitor.visit(*this); }
};
class OrExpression final : public GroupExpression {
public:
    using GroupExpression::GroupExpression;
    Hits evaluate(const QuerySource&) const override;
    void accept(ExpressionVisitor& visitor) const override { visitor.visit(*this); }
};
std::shared_ptr<const Expression> parse_expression(std::string_view text);
class TermCountVisitor final : public ExpressionVisitor {
public:
    void visit(const TermExpression&) override { ++count; }
    void visit(const AndExpression&) override;
    void visit(const OrExpression&) override;
    std::size_t count{0};
};
class ExplainVisitor final : public ExpressionVisitor {
public:
    void visit(const TermExpression&) override;
    void visit(const AndExpression&) override;
    void visit(const OrExpression&) override;
    std::string text;
};

// L4-021-strategy: one request pipeline, two replaceable ordering algorithms.
class HitOrder {
public:
    virtual ~HitOrder() = default;
    virtual void sort(Hits&) const = 0;
};
class LineOrder final : public HitOrder {
public:
    void sort(Hits&) const override;
};
class LengthOrder final : public HitOrder {
public:
    void sort(Hits&) const override;
};
struct QueryRequest {
    std::shared_ptr<const Expression> expression;
    LineRange range;
    std::size_t limit;
    std::shared_ptr<const HitOrder> order;
};
// L4-004-builder: an owned validated request, never a reference into a builder.
class QueryBuilder {
public:
    QueryBuilder& expression(std::string value);
    QueryBuilder& range(LineRange value);
    QueryBuilder& limit(std::size_t value);
    QueryBuilder& order(std::shared_ptr<const HitOrder> value);
    QueryRequest build() const;

private:
    std::string expression_;
    LineRange range_;
    std::size_t limit_{std::numeric_limits<std::size_t>::max()};
    std::shared_ptr<const HitOrder> order_{std::make_shared<LineOrder>()};
};
Hits execute_query(const QuerySource&, const QueryRequest&);

// L4-007-bridge: renderers and sources vary independently, without cross-product subclasses.
class QueryRenderer {
public:
    explicit QueryRenderer(std::shared_ptr<QuerySource> source);
    virtual ~QueryRenderer() = default;
    void run(const QueryRequest&, std::ostream&) const;
    virtual void render(const Hits&, std::ostream&) const = 0;

private:
    std::shared_ptr<QuerySource> source_;
};
class PlainRenderer final : public QueryRenderer {
public:
    using QueryRenderer::QueryRenderer;
    void render(const Hits&, std::ostream&) const override;
};
class TsvRenderer final : public QueryRenderer {
public:
    using QueryRenderer::QueryRenderer;
    void render(const Hits&, std::ostream&) const override;
};

enum class ErrorLevel { input, io, internal };
// L4-013-chain-of-responsibility: acyclic owned chain, unhandled errors terminate explicitly.
class ErrorHandler {
public:
    ErrorHandler(ErrorLevel level, int code, std::unique_ptr<ErrorHandler> next = nullptr);
    int report(ErrorLevel level, std::string_view message, std::ostream& error) const;

private:
    ErrorLevel level_;
    int code_;
    std::unique_ptr<ErrorHandler> next_;
};
std::unique_ptr<ErrorHandler> diagnostic_chain();

// L4-014-command: save the exact previous snapshot, not an inverse rebuild.
class RebuildCommand {
public:
    RebuildCommand(InvertedIndex& index, std::string path)
        : index_(index), path_(std::move(path)) {}
    void execute();
    void undo();

private:
    InvertedIndex& index_;
    std::string path_;
    std::optional<InvertedIndex::Snapshot> previous_;
};

class BuildJob;
// L4-020-state: state objects own transition behavior; context never switches on a tag.
class TaskState {
public:
    virtual ~TaskState() = default;
    virtual std::string_view name() const noexcept = 0;
    virtual void request(BuildJob&) const = 0;
};
class BuildJob {
public:
    explicit BuildJob(std::function<void()> work);
    void request();
    std::string_view state() const noexcept;
    void transition(std::unique_ptr<TaskState> state);
    void execute();

private:
    std::function<void()> work_;
    std::shared_ptr<TaskState> state_;
};

class ResultView {
public:
    virtual ~ResultView() = default;
    virtual void display(const Hits&) = 0;
};
// L4-017-mediator: editor and result view communicate only through the session.
// L4-019-observer: weak subscriptions; notification traverses a copy, in registration order.
class QuerySession {
public:
    QuerySession(InvertedIndex index, QueryRequest request);
    void attach(std::shared_ptr<ResultView> view);
    std::size_t subscribe(std::shared_ptr<UpdateListener> listener);
    void unsubscribe(std::size_t id);
    void replace(InvertedIndex index);
    void change(QueryRequest request);
    Hits search() const;
    std::shared_ptr<SnapshotSource> source() const { return source_; }
    class Memento {
        friend class QuerySession;
        explicit Memento(QueryRequest request) : request_(std::move(request)) {}
        QueryRequest request_;
    };
    Memento save() const { return Memento(request_); }
    void restore(const Memento&);

private:
    std::shared_ptr<SnapshotSource> source_;
    QueryRequest request_;
    std::weak_ptr<ResultView> view_;
    std::vector<std::pair<std::size_t, std::weak_ptr<UpdateListener>>> listeners_;
    std::size_t next_id_{0};
};
class QueryEditor {
public:
    explicit QueryEditor(QuerySession& session) : session_(session) {}
    void submit(QueryRequest request) { session_.change(std::move(request)); }

private:
    QuerySession& session_;
};

// L4-010-facade L2-009-project-layers: load, parse/query, render via existing subsystems.
class IndexApplication {
public:
    void run(const std::string& path, std::string_view expression, std::ostream& output) const;
};

} // namespace devbox

#endif
