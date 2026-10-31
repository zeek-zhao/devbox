#include "index.h"

#include <cassert>
#include <filesystem>
#include <fstream>
#include <sstream>
#include <thread>
#include <unistd.h>

namespace {
using namespace devbox;

class File {
public:
    File() {
        auto name = (std::filesystem::temp_directory_path() / "devbox-query-XXXXXX").string();
        const auto fd = mkstemp(name.data());
        if (fd == -1) {
            throw std::runtime_error("mkstemp failed");
        }
        close(fd);
        path = name;
    }
    ~File() { std::filesystem::remove(path); }
    File(const File&) = delete;
    File& operator=(const File&) = delete;
    void write(const std::string& text) {
        std::ofstream out(path, std::ios::binary | std::ios::trunc);
        out.exceptions(std::ios::failbit | std::ios::badbit);
        out << text;
    }
    std::string path;
};
template <typename Exception, typename Function> void throws(Function function) {
    bool failed = false;
    try {
        function();
    } catch (const Exception&) {
        failed = true;
    }
    assert(failed);
}
InvertedIndex make_index(File& file, const std::string& text) {
    file.write(text);
    InvertedIndex index;
    assert(index.build(file.path));
    return index;
}
std::vector<std::size_t> numbers(const Hits& hits) {
    std::vector<std::size_t> result;
    for (const auto& hit : hits) {
        result.push_back(hit.number);
    }
    return result;
}

// L2-005-test-harness L4-022-template-method: Release keeps assertions;
// subclasses cannot replace the prepare/exercise/verify ordering.
class TestCase {
public:
    virtual ~TestCase() = default;
    void run() {
        prepare();
        exercise();
        verify();
    }

protected:
    virtual void prepare() = 0;
    virtual void exercise() = 0;
    virtual void verify() = 0;
};
class ParallelCase final : public TestCase {
    File file_;
    InvertedIndex serial_, parallel_;
    void prepare() override {
        std::string text;
        for (int i = 0; i < 2000; ++i) {
            text += i % 2 == 0 ? "Alpha\tbeta alpha\n" : "gamma ALPHA\n";
        }
        file_.write(text);
        assert(serial_.build(file_.path, 1, TextParserFactory{}));
    }
    void exercise() override {
        for (int repeat = 0; repeat < 8; ++repeat) {
            assert(parallel_.build(file_.path, 4, TsvParserFactory{}));
            assert(parallel_.statistics() == serial_.statistics());
        }
    }
    void verify() override {
        assert(parallel_.terms() == serial_.terms());
        for (const auto& word : serial_.terms()) {
            assert(*parallel_.find(word) == *serial_.find(word));
        }
        assert(parallel_.frequency("alpha") == std::optional<std::size_t>{2000});
        throws<std::invalid_argument>([&] { parallel_.build(file_.path, 0, TextParserFactory{}); });
        file_.write("");
        assert(parallel_.build(file_.path, 4, TextParserFactory{}));
        assert(parallel_.terms().empty());
        assert(!parallel_.build(file_.path + "/missing"));
        assert(parallel_.last_error().find(file_.path) != std::string::npos);
        assert(!parallel_.build(std::filesystem::temp_directory_path().string()));
    }
};
class SerializationCase final : public TestCase {
    File text_, binary_;
    InvertedIndex original_, loaded_;
    std::string encoded_;
    void prepare() override {
        original_ = make_index(text_, std::string("Alpha\n\nbeta\0end", 15));
        original_.save(binary_.path);
        std::ifstream input(binary_.path, std::ios::binary);
        encoded_.assign(std::istreambuf_iterator<char>(input), {});
        assert(encoded_.substr(0, 8) == std::string("DBIX\1\0\0\0", 8));
        assert(static_cast<unsigned char>(encoded_[8]) == 3);
        assert(static_cast<unsigned char>(encoded_[16]) == 5);
    }
    void exercise() override {
        loaded_.load(binary_.path);
        for (std::size_t length = 0; length < encoded_.size(); ++length) {
            binary_.write(encoded_.substr(0, length));
            throws<std::runtime_error>([&] { loaded_.load(binary_.path); });
            assert(loaded_.statistics() == original_.statistics());
        }
        auto corrupt = encoded_;
        corrupt[4] = 2;
        binary_.write(corrupt);
        throws<std::runtime_error>([&] { loaded_.load(binary_.path); });
        corrupt = encoded_;
        corrupt[8] = static_cast<char>(255);
        binary_.write(corrupt);
        throws<std::runtime_error>([&] { loaded_.load(binary_.path); });
        corrupt = encoded_;
        corrupt[16] = static_cast<char>(255);
        binary_.write(corrupt);
        throws<std::runtime_error>([&] { loaded_.load(binary_.path); });
        const auto dictionary = std::size_t{16} + original_.line(1).size() + 8 +
                                original_.line(2).size() + 8 + original_.line(3).size() + 8;
        const auto word = dictionary + 16;
        const auto posting_count = word + 5; // first sorted word is "alpha".
        for (auto offset : {dictionary, dictionary + 8, word, posting_count, posting_count + 8}) {
            corrupt = encoded_;
            corrupt.at(offset) = offset == word ? 'A' : static_cast<char>(255);
            binary_.write(corrupt);
            throws<std::runtime_error>([&] { loaded_.load(binary_.path); });
        }
        binary_.write(encoded_ + "x");
        throws<std::runtime_error>([&] { loaded_.load(binary_.path); });
    }
    void verify() override {
        assert(loaded_.terms() == original_.terms());
        assert(loaded_.line(3) == original_.line(3));
        assert(*loaded_.find("alpha") == *original_.find("alpha"));
        throws<std::logic_error>([&] { InvertedIndex{}.save(binary_.path); });
        original_ = make_index(text_, "");
        original_.save(binary_.path);
        loaded_.load(binary_.path);
        assert(loaded_.state() == InvertedIndex::State::ready && loaded_.terms().empty());
    }
};

struct View final : ResultView {
    Hits hits;
    void display(const Hits& value) override { hits = value; }
};
struct Listener final : UpdateListener {
    std::function<void()> callback;
    explicit Listener(std::function<void()> callback) : callback(std::move(callback)) {}
    void updated() override { callback(); }
};
class BrokenParserFactory final : public ParserFactory {
public:
    std::unique_ptr<TokenParser> create() const override {
        throw std::runtime_error("parser failure");
    }
};
} // namespace

int main() {
    ParallelCase{}.run();
    SerializationCase{}.run();
    File file, disk;
    auto index = make_index(file, "alpha beta alpha\ngamma alpha\ndelta\n");
    auto source = std::make_shared<SnapshotSource>(index);

    auto& config = IndexConfig::instance();
    assert(&config == &IndexConfig::instance());
    config.workers(2);
    assert(IndexConfig::instance().workers() == 2);
    config.workers(1);
    throws<std::invalid_argument>([&] { config.workers(65); });
    TokenPool pool;
    auto one = pool.intern("alpha");
    assert(one == pool.intern("alpha"));
    assert(one != pool.intern("beta") && pool.size() == 2);
    for (const auto& [factory, size] :
         std::vector<std::pair<std::shared_ptr<ParserFactory>, std::size_t>>{
             {std::make_shared<TextParserFactory>(), 4},
             {std::make_shared<TsvParserFactory>(), 3}}) {
        auto tokens = factory->create()->parse("doc7\tALPHA beta ALPHA!", pool);
        assert(tokens.size() == size && tokens.at(size - 3) == one && tokens.back() == one);
    }
    file.write("doc7\talpha beta\n");
    InvertedIndex tsv_index;
    assert(tsv_index.build(file.path, 1, TsvParserFactory{}));
    assert(tsv_index.find("doc7") == nullptr && tsv_index.find("alpha") != nullptr);
    tsv_index.save(disk.path);
    InvertedIndex tsv_loaded;
    tsv_loaded.load(disk.path);
    assert(tsv_loaded.terms() == tsv_index.terms() && tsv_loaded.find("doc7") == nullptr);
    file.write("alpha beta alpha\ngamma alpha\ndelta\n");
    throws<std::runtime_error>([&] { index.build(file.path, 4, BrokenParserFactory{}); });
    assert(index.find("alpha") != nullptr);

    std::unique_ptr<IndexPrototype> prototype = source->clone();
    assert(prototype->index().find("alpha") == source->index().find("alpha"));
    auto replacement = make_index(file, "beta\ndelta beta\n");
    prototype->replace(replacement);
    assert(!prototype->index().find("alpha") && source->index().find("alpha"));
    auto adapter = std::make_shared<LegacyQueryAdapter>(index);
    assert(adapter->lookup("ALPHA") == source->lookup("alpha"));
    throws<std::invalid_argument>([&] { adapter->lookup("bad!"); });

    index.save(disk.path);
    auto lazy = std::make_shared<LazyQuery>(disk.path);
    assert(!lazy->loaded() && lazy->calls() == 0);
    {
        std::vector<std::jthread> readers;
        for (int i = 0; i < 8; ++i) {
            readers.emplace_back([&] { assert(lazy->lookup("alpha") == source->lookup("alpha")); });
        }
    }
    assert(lazy->loaded() && lazy->calls() == 8);
    std::filesystem::remove(disk.path);
    assert(lazy->lookup("alpha") == source->lookup("alpha"));
    index.save(disk.path);
    LazyQuery missing(disk.path + "/missing");
    throws<std::runtime_error>([&] { missing.lookup("alpha"); });
    assert(!missing.loaded());
    for (const std::shared_ptr<BackendFactory>& factory :
         std::vector<std::shared_ptr<BackendFactory>>{
             std::make_shared<MemoryBackendFactory>(),
             std::make_shared<LocalBackendFactory>(disk.path)}) {
        auto backend = factory->create(index);
        assert(backend.source()->lookup("alpha") == source->lookup("alpha"));
        assert(backend.store().read().statistics() == index.statistics());
        backend.store().write(replacement);
        assert(backend.source()->lookup("alpha").empty());
        assert(backend.store().read().frequency("beta") == std::optional<std::size_t>{2});
    }
    auto counter = std::make_shared<CountingQuery>(source);
    auto cache = std::make_shared<CachedQuery>(counter);
    assert(cache->lookup("alpha") == cache->lookup("alpha"));
    assert(counter->calls() == 1);
    cache->updated();
    cache->lookup("alpha");
    assert(counter->calls() == 2);
    auto outer_counter = std::make_shared<CountingQuery>(cache);
    outer_counter->lookup("alpha");
    outer_counter->lookup("alpha");
    assert(outer_counter->calls() == 2 && counter->calls() == 2);
    throws<std::invalid_argument>([] { CachedQuery bad(nullptr); });

    const auto request = QueryBuilder{}.expression("alpha").build();
    const auto expression = parse_expression("(alpha AND beta) OR delta");
    assert((numbers(expression->evaluate(*source)) == std::vector<std::size_t>{1, 3}));
    assert((numbers(parse_expression("alpha OR beta AND delta")->evaluate(*source)) ==
            std::vector<std::size_t>{1, 2}));
    assert(parse_expression("missing AND alpha")->evaluate(*source).empty());
    for (auto bad : {"", "alpha!", "alpha beta", "alpha AND", "(alpha", "alpha)", "OR alpha"}) {
        throws<std::invalid_argument>([&] { parse_expression(bad); });
    }
    throws<std::invalid_argument>([&] { parse_expression(std::string(66, '(') + "alpha"); });
    TermCountVisitor count;
    expression->accept(count);
    assert(count.count == 3);
    ExplainVisitor explain;
    expression->accept(explain);
    assert(explain.text == "((alpha AND beta) OR delta)");
    TermExpression leaf("ALPHA");
    TermCountVisitor leaf_count;
    ExplainVisitor leaf_explain;
    leaf.accept(leaf_count);
    leaf.accept(leaf_explain);
    assert(leaf_count.count == 1 && leaf_explain.text == "alpha");

    throws<std::invalid_argument>([] { QueryBuilder{}.build(); });
    throws<std::invalid_argument>([] { QueryBuilder{}.expression("alpha").limit(0); });
    throws<std::invalid_argument>([] { QueryBuilder{}.range({0, 3}); });
    throws<std::invalid_argument>([] { QueryBuilder{}.order(nullptr); });
    auto builder = QueryBuilder{}.expression("alpha").range({2, 3}).limit(1);
    auto bounded = builder.build();
    builder.expression("beta");
    assert((numbers(execute_query(*source, bounded)) == std::vector<std::size_t>{2}));
    auto length = QueryBuilder{}.expression("alpha").order(std::make_shared<LengthOrder>()).build();
    assert((numbers(execute_query(*source, length)) == std::vector<std::size_t>{2, 1}));
    assert((numbers(execute_query(*source, request)) == std::vector<std::size_t>{1, 2}));
    const auto iterated = index.query("alpha");
    for (auto number : std::get<InvertedIndex::Match>(iterated)) {
        assert(number == 1 || number == 2);
    }
    assert((index.terms() == std::vector<std::string>{"alpha", "beta", "delta", "gamma"}));
    const auto vocabulary = index.vocabulary();
    std::vector<std::string> visited;
    auto iterator = vocabulary.begin();
    while (iterator != vocabulary.end()) {
        visited.push_back(*iterator++);
    }
    assert(iterator == vocabulary.end() && visited == index.terms());
    auto changed_index = index;
    assert(changed_index.build(file.path));
    visited.clear();
    for (const auto& word : vocabulary) {
        visited.push_back(word);
    }
    assert(visited == index.terms());
    // Both renderers × both sources must produce identical data, not just labels.
    index.save(disk.path);
    for (const auto& input : std::vector<std::shared_ptr<QuerySource>>{adapter, lazy}) {
        std::ostringstream plain, tsv;
        PlainRenderer(input).run(request, plain);
        TsvRenderer(input).run(request, tsv);
        assert(plain.str() == "1: alpha beta alpha\n2: gamma alpha\n");
        assert(tsv.str() == "1\talpha beta alpha\n2\tgamma alpha\n");
    }
    std::ostringstream escaped;
    TsvRenderer(source).render({{1, "a\tb\\c\r"}}, escaped);
    assert(escaped.str() == "1\ta\\tb\\\\c\\r\n");

    auto errors = diagnostic_chain();
    for (const auto& [level, code] :
         {std::pair{ErrorLevel::input, 2}, {ErrorLevel::io, 1}, {ErrorLevel::internal, 1}}) {
        std::ostringstream out;
        assert(errors->report(level, "context/path", out) == code);
        assert(out.str() == "context/path\n");
    }
    ErrorHandler short_chain(ErrorLevel::input, 2);
    std::ostringstream unhandled;
    assert(short_chain.report(ErrorLevel::io, "disk", unhandled) == 1);
    assert(unhandled.str() == "unhandled error: disk\n");

    const auto before = index.checkpoint();
    RebuildCommand command(index, file.path);
    throws<std::logic_error>([&] { command.undo(); });
    command.execute();
    assert(index.find("alpha") == nullptr);
    throws<std::logic_error>([&] { command.execute(); });
    command.undo();
    assert(index.find("alpha") != nullptr);
    index.restore(before);
    RebuildCommand failed(index, file.path + "/missing");
    throws<std::runtime_error>([&] { failed.execute(); });
    assert(index.find("alpha") != nullptr);
    int jobs = 0;
    BuildJob job([&] { ++jobs; });
    assert(job.state() == "pending");
    job.request();
    assert(job.state() == "running" && jobs == 0);
    job.request();
    assert(job.state() == "done" && jobs == 1);
    throws<std::logic_error>([&] { job.request(); });
    assert(job.state() == "done");
    BuildJob bad_job([] { throw std::runtime_error("job failure"); });
    bad_job.request();
    throws<std::runtime_error>([&] { bad_job.request(); });
    assert(bad_job.state() == "running");
    BuildJob* inspecting = nullptr;
    BuildJob inspected([&] { assert(inspecting->state() == "running"); });
    inspecting = &inspected;
    inspected.request();
    inspected.request();

    QuerySession session(index, request);
    QueryEditor editor(session);
    auto view = std::make_shared<View>();
    session.attach(view);
    auto saved = session.save();
    editor.submit(QueryBuilder{}.expression("delta").build());
    assert((numbers(view->hits) == std::vector<std::size_t>{3}));
    session.restore(saved);
    assert((numbers(view->hits) == std::vector<std::size_t>{1, 2}));
    auto session_cache = std::make_shared<CachedQuery>(session.source());
    session.subscribe(session_cache);
    assert(session_cache->lookup("alpha").size() == 2);
    std::vector<int> notifications;
    auto first = std::make_shared<Listener>([&] { notifications.push_back(1); });
    auto second = std::make_shared<Listener>([&] { notifications.push_back(2); });
    const auto first_id = session.subscribe(first);
    session.subscribe(second);
    session.replace(replacement);
    assert(session_cache->lookup("alpha").empty());
    assert((notifications == std::vector<int>{1, 2}));
    session.unsubscribe(first_id);
    notifications.clear();
    session.replace(index);
    assert((notifications == std::vector<int>{2}));
    auto mutating = std::make_shared<Listener>([&] { session.unsubscribe(first_id); });
    session.subscribe(mutating);
    session.replace(index);
    auto throwing = std::make_shared<Listener>([] { throw std::runtime_error("listener failed"); });
    session.subscribe(throwing);
    auto late_cache = std::make_shared<CachedQuery>(session.source());
    session.subscribe(late_cache);
    assert(late_cache->lookup("alpha").size() == 2);
    throws<std::runtime_error>([&] { session.replace(replacement); });
    assert(late_cache->lookup("alpha").empty());
    file.write("alpha beta alpha\ngamma alpha\ndelta\n");
    std::ostringstream output;
    IndexApplication{}.run(file.path, "(alpha AND beta) OR delta", output);
    assert(output.str() == "1: alpha beta alpha\n3: delta\n");
}
