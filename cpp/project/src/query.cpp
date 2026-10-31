#include "index.h"

#include <cctype>
#include <exception>
#include <iterator>
#include <ostream>
#include <sstream>

namespace devbox {
namespace {
Hits matches(const InvertedIndex::QueryResult& result) {
    if (std::holds_alternative<InvertedIndex::QueryError>(result)) {
        throw std::invalid_argument("query must be one ASCII word");
    }
    Hits hits;
    if (const auto* match = std::get_if<InvertedIndex::Match>(&result)) {
        match->for_each(
            [&](std::size_t number, const std::string& text) { hits.push_back({number, text}); });
    }
    return hits;
}
void require_source(const std::shared_ptr<QuerySource>& source) {
    if (!source) {
        throw std::invalid_argument("query source is null");
    }
}
bool by_line(const Hit& left, const Hit& right) {
    return left.number < right.number;
}

class MemoryStore final : public SnapshotStore {
public:
    explicit MemoryStore(std::shared_ptr<SnapshotSource> source) : source_(std::move(source)) {}
    void write(const InvertedIndex& index) override { source_->replace(index); }
    InvertedIndex read() const override { return source_->index(); }

private:
    std::shared_ptr<SnapshotSource> source_;
};
class LocalStore final : public SnapshotStore {
public:
    LocalStore(std::string path, std::shared_ptr<SnapshotSource> source)
        : path_(std::move(path)), source_(std::move(source)) {}
    void write(const InvertedIndex& index) override {
        index.save(path_);
        source_->replace(index);
    }
    InvertedIndex read() const override {
        InvertedIndex index;
        index.load(path_);
        return index;
    }

private:
    std::string path_;
    std::shared_ptr<SnapshotSource> source_;
};
} // namespace

Hits SnapshotSource::lookup(std::string_view word) const {
    return matches(index_.query(word));
}
std::unique_ptr<IndexPrototype> SnapshotSource::clone() const {
    return std::make_unique<SnapshotSource>(index_);
}
Hits LegacyQueryAdapter::lookup(std::string_view word) const {
    // Validation uses the public query contract; actual hits use the legacy interface.
    if (std::holds_alternative<InvertedIndex::QueryError>(index_.query(word))) {
        throw std::invalid_argument("query must be one ASCII word");
    }
    Hits result;
    if (const auto* lines = index_.find(word)) {
        for (auto number : *lines) {
            result.push_back({number, index_.line(number)});
        }
    }
    return result;
}
Hits LazyQuery::lookup(std::string_view word) const {
    calls_.fetch_add(1, std::memory_order_relaxed);
    std::lock_guard lock(mutex_);
    if (!source_) {
        InvertedIndex index;
        index.load(path_);
        source_ = std::make_unique<SnapshotSource>(std::move(index));
    }
    return source_->lookup(word);
}
bool LazyQuery::loaded() const {
    std::lock_guard lock(mutex_);
    return source_ != nullptr;
}
Backend MemoryBackendFactory::create(InvertedIndex index) const {
    auto source = std::make_shared<SnapshotSource>(std::move(index));
    return Backend(source, std::make_shared<MemoryStore>(source));
}
Backend LocalBackendFactory::create(InvertedIndex index) const {
    auto source = std::make_shared<SnapshotSource>(index);
    auto store = std::make_shared<LocalStore>(path_, source);
    store->write(index);
    return Backend(source, std::move(store));
}
CountingQuery::CountingQuery(std::shared_ptr<QuerySource> inner) : inner_(std::move(inner)) {
    require_source(inner_);
}
Hits CountingQuery::lookup(std::string_view word) const {
    calls_.fetch_add(1, std::memory_order_relaxed);
    return inner_->lookup(word);
}
CachedQuery::CachedQuery(std::shared_ptr<QuerySource> inner) : inner_(std::move(inner)) {
    require_source(inner_);
}
Hits CachedQuery::lookup(std::string_view word) const {
    const std::string key(word);
    const auto found = cache_.find(key);
    if (found != cache_.end()) {
        return found->second;
    }
    auto result = inner_->lookup(word);
    cache_.emplace(key, result);
    return result;
}
void CachedQuery::updated() {
    cache_.clear();
}

TermExpression::TermExpression(std::string word) : word_(std::move(word)) {
    if (word_.empty()) {
        throw std::invalid_argument("empty query term");
    }
    for (auto& ch : word_) {
        if (!((ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || (ch >= '0' && ch <= '9'))) {
            throw std::invalid_argument("invalid character in query term");
        }
        if (ch >= 'A' && ch <= 'Z') {
            ch = static_cast<char>(ch - 'A' + 'a');
        }
    }
}
Hits TermExpression::evaluate(const QuerySource& source) const {
    return source.lookup(word_);
}
GroupExpression::GroupExpression(std::vector<std::shared_ptr<const Expression>> children)
    : children_(std::move(children)) {
    if (children_.size() < 2 ||
        std::any_of(children_.begin(), children_.end(), [](const auto& node) { return !node; })) {
        throw std::invalid_argument("query group requires at least two non-null children");
    }
}
Hits AndExpression::evaluate(const QuerySource& source) const {
    auto result = children().front()->evaluate(source);
    for (std::size_t i = 1; i < children().size(); ++i) {
        auto right = children()[i]->evaluate(source);
        Hits next;
        std::set_intersection(result.begin(), result.end(), right.begin(), right.end(),
                              std::back_inserter(next), by_line);
        result = std::move(next);
    }
    return result;
}
Hits OrExpression::evaluate(const QuerySource& source) const {
    Hits result;
    for (const auto& child : children()) {
        auto right = child->evaluate(source);
        Hits next;
        std::set_union(result.begin(), result.end(), right.begin(), right.end(),
                       std::back_inserter(next), by_line);
        result = std::move(next);
    }
    return result;
}

namespace {
class ExpressionParser {
public:
    explicit ExpressionParser(std::string_view text) : text_(text) { advance(); }
    std::shared_ptr<const Expression> parse() {
        auto result = disjunction(0);
        if (!token_.empty()) {
            throw std::invalid_argument("unexpected query token: " + token_);
        }
        return result;
    }

private:
    void advance() {
        while (!text_.empty() && (text_.front() == ' ' || text_.front() == '\t')) {
            text_.remove_prefix(1);
        }
        token_.clear();
        if (text_.empty()) {
            return;
        }
        if (text_.front() == '(' || text_.front() == ')') {
            token_ = text_.front();
            text_.remove_prefix(1);
            return;
        }
        const auto end = text_.find_first_of(" \t()");
        token_ = text_.substr(0, end);
        text_.remove_prefix(token_.size());
    }
    std::shared_ptr<const Expression> primary(std::size_t depth) {
        if (depth > 64) {
            throw std::invalid_argument("query nesting exceeds 64");
        }
        if (token_ == "(") {
            advance();
            auto result = disjunction(depth + 1);
            if (token_ != ")") {
                throw std::invalid_argument("missing query closing parenthesis");
            }
            advance();
            return result;
        }
        if (token_.empty() || token_ == ")" || token_ == "AND" || token_ == "OR") {
            throw std::invalid_argument("expected query term");
        }
        auto result = std::make_shared<TermExpression>(token_);
        advance();
        return result;
    }
    std::shared_ptr<const Expression> conjunction(std::size_t depth) {
        std::vector<std::shared_ptr<const Expression>> nodes{primary(depth)};
        while (token_ == "AND") {
            advance();
            nodes.push_back(primary(depth));
        }
        return nodes.size() == 1 ? nodes.front()
                                 : std::make_shared<AndExpression>(std::move(nodes));
    }
    std::shared_ptr<const Expression> disjunction(std::size_t depth) {
        std::vector<std::shared_ptr<const Expression>> nodes{conjunction(depth)};
        while (token_ == "OR") {
            advance();
            nodes.push_back(conjunction(depth));
        }
        return nodes.size() == 1 ? nodes.front() : std::make_shared<OrExpression>(std::move(nodes));
    }
    std::string_view text_;
    std::string token_;
};
void count_group(const GroupExpression& node, TermCountVisitor& visitor) {
    for (const auto& child : node.children()) {
        child->accept(visitor);
    }
}
void explain_group(const GroupExpression& node, std::string_view op, ExplainVisitor& visitor) {
    visitor.text += '(';
    bool first = true;
    for (const auto& child : node.children()) {
        if (!first) {
            visitor.text += op;
        }
        first = false;
        child->accept(visitor);
    }
    visitor.text += ')';
}
} // namespace
std::shared_ptr<const Expression> parse_expression(std::string_view text) {
    return ExpressionParser(text).parse();
}
void TermCountVisitor::visit(const AndExpression& node) {
    count_group(node, *this);
}
void TermCountVisitor::visit(const OrExpression& node) {
    count_group(node, *this);
}
void ExplainVisitor::visit(const TermExpression& node) {
    text += node.word();
}
void ExplainVisitor::visit(const AndExpression& node) {
    explain_group(node, " AND ", *this);
}
void ExplainVisitor::visit(const OrExpression& node) {
    explain_group(node, " OR ", *this);
}
void LineOrder::sort(Hits& hits) const {
    std::stable_sort(hits.begin(), hits.end(), by_line);
}
void LengthOrder::sort(Hits& hits) const {
    std::stable_sort(hits.begin(), hits.end(), [](const Hit& left, const Hit& right) {
        return left.text.size() < right.text.size();
    });
}
QueryBuilder& QueryBuilder::expression(std::string value) {
    expression_ = std::move(value);
    return *this;
}
QueryBuilder& QueryBuilder::range(LineRange value) {
    RangePredicate validate(value);
    range_ = value;
    return *this;
}
QueryBuilder& QueryBuilder::limit(std::size_t value) {
    if (value == 0) {
        throw std::invalid_argument("query limit must be positive");
    }
    limit_ = value;
    return *this;
}
QueryBuilder& QueryBuilder::order(std::shared_ptr<const HitOrder> value) {
    if (!value) {
        throw std::invalid_argument("query order is null");
    }
    order_ = std::move(value);
    return *this;
}
QueryRequest QueryBuilder::build() const {
    return {parse_expression(expression_), range_, limit_, order_};
}
Hits execute_query(const QuerySource& source, const QueryRequest& request) {
    if (!request.expression || !request.order || request.limit == 0) {
        throw std::invalid_argument("incomplete query request");
    }
    RangePredicate validate(request.range);
    auto hits = request.expression->evaluate(source);
    std::erase_if(hits, [&](const Hit& hit) { return !request.range.contains(hit.number); });
    request.order->sort(hits);
    if (hits.size() > request.limit) {
        hits.resize(request.limit);
    }
    return hits;
}
QueryRenderer::QueryRenderer(std::shared_ptr<QuerySource> source) : source_(std::move(source)) {
    require_source(source_);
}
void QueryRenderer::run(const QueryRequest& request, std::ostream& output) const {
    render(execute_query(*source_, request), output);
}
void PlainRenderer::render(const Hits& hits, std::ostream& output) const {
    if (hits.empty()) {
        output << "NO_MATCH\n";
    }
    for (const auto& hit : hits) {
        output << hit.number << ": " << hit.text << '\n';
    }
}
void TsvRenderer::render(const Hits& hits, std::ostream& output) const {
    for (const auto& hit : hits) {
        output << hit.number << '\t';
        for (char ch : hit.text) {
            switch (ch) {
            case '\\':
                output << "\\\\";
                break;
            case '\t':
                output << "\\t";
                break;
            case '\r':
                output << "\\r";
                break;
            case '\n':
                output << "\\n";
                break;
            default:
                output << ch;
                break;
            }
        }
        output << '\n';
    }
}
ErrorHandler::ErrorHandler(ErrorLevel level, int code, std::unique_ptr<ErrorHandler> next)
    : level_(level), code_(code), next_(std::move(next)) {}
int ErrorHandler::report(ErrorLevel level, std::string_view message, std::ostream& error) const {
    if (level == level_) {
        error << message << '\n';
        return code_;
    }
    if (next_) {
        return next_->report(level, message, error);
    }
    error << "unhandled error: " << message << '\n';
    return 1;
}
std::unique_ptr<ErrorHandler> diagnostic_chain() {
    return std::make_unique<ErrorHandler>(
        ErrorLevel::input, 2,
        std::make_unique<ErrorHandler>(ErrorLevel::io, 1,
                                       std::make_unique<ErrorHandler>(ErrorLevel::internal, 1)));
}
void RebuildCommand::execute() {
    if (previous_) {
        throw std::logic_error("rebuild command already executed");
    }
    auto before = index_.checkpoint();
    if (!index_.build(path_)) {
        throw std::runtime_error(index_.last_error());
    }
    previous_ = std::move(before);
}
void RebuildCommand::undo() {
    if (!previous_) {
        throw std::logic_error("cannot undo an unexecuted command");
    }
    index_.restore(*previous_);
    previous_.reset();
}

namespace {
class DoneTask final : public TaskState {
public:
    std::string_view name() const noexcept override { return "done"; }
    void request(BuildJob&) const override { throw std::logic_error("build job already done"); }
};
class RunningTask final : public TaskState {
public:
    std::string_view name() const noexcept override { return "running"; }
    void request(BuildJob& job) const override {
        job.execute();
        job.transition(std::make_unique<DoneTask>());
    }
};
class PendingTask final : public TaskState {
public:
    std::string_view name() const noexcept override { return "pending"; }
    void request(BuildJob& job) const override { job.transition(std::make_unique<RunningTask>()); }
};
} // namespace
BuildJob::BuildJob(std::function<void()> work)
    : work_(std::move(work)), state_(std::make_unique<PendingTask>()) {
    if (!work_) {
        throw std::invalid_argument("build job has no work");
    }
}
void BuildJob::request() {
    // Keep the active state alive while it replaces itself.
    const auto active = state_;
    active->request(*this);
}
std::string_view BuildJob::state() const noexcept {
    return state_->name();
}
void BuildJob::transition(std::unique_ptr<TaskState> state) {
    if (!state) {
        throw std::invalid_argument("null task state");
    }
    state_ = std::move(state);
}
void BuildJob::execute() {
    work_();
}

QuerySession::QuerySession(InvertedIndex index, QueryRequest request)
    : source_(std::make_shared<SnapshotSource>(std::move(index))), request_(std::move(request)) {
    execute_query(*source_, request_);
}
void QuerySession::attach(std::shared_ptr<ResultView> view) {
    if (!view) {
        throw std::invalid_argument("null result view");
    }
    view_ = view;
}
std::size_t QuerySession::subscribe(std::shared_ptr<UpdateListener> listener) {
    if (!listener) {
        throw std::invalid_argument("null update listener");
    }
    const auto id = detail::checked_add(next_id_, std::size_t{1});
    listeners_.emplace_back(id, listener);
    next_id_ = id;
    return id;
}
void QuerySession::unsubscribe(std::size_t id) {
    std::erase_if(listeners_, [&](const auto& entry) { return entry.first == id; });
}
void QuerySession::replace(InvertedIndex index) {
    const auto listeners = listeners_;
    source_->replace(std::move(index));
    std::exception_ptr failure;
    for (const auto& [id, weak] : listeners) {
        if (auto listener = weak.lock()) {
            try {
                listener->updated();
            } catch (...) {
                // Still invalidate every cache, then surface the first callback failure.
                if (!failure) {
                    failure = std::current_exception();
                }
            }
        }
    }
    if (failure) {
        std::rethrow_exception(failure);
    }
    if (auto view = view_.lock()) {
        view->display(search());
    }
}
void QuerySession::change(QueryRequest request) {
    auto hits = execute_query(*source_, request);
    request_ = std::move(request);
    if (auto view = view_.lock()) {
        view->display(hits);
    }
}
Hits QuerySession::search() const {
    return execute_query(*source_, request_);
}
void QuerySession::restore(const Memento& memento) {
    change(memento.request_);
}
void IndexApplication::run(const std::string& path, std::string_view expression,
                           std::ostream& output) const {
    const auto request = QueryBuilder{}.expression(std::string(expression)).build();
    InvertedIndex index;
    if (!index.build(path)) {
        throw std::runtime_error(index.last_error());
    }
    auto backend = MemoryBackendFactory{}.create(std::move(index));
    PlainRenderer(backend.source()).run(request, output);
}
} // namespace devbox
