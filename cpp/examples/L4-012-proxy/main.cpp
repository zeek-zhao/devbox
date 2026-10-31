#include <iostream>
#include <memory>
#include <string_view>

class Query {
public:
    virtual ~Query() = default;
    virtual std::string_view execute() = 0;
};

class RealQuery final : public Query {
public:
    RealQuery() { ++construction_count_; }
    std::string_view execute() override { return "real result"; }
    static int construction_count() { return construction_count_; }

private:
    inline static int construction_count_ = 0;
};

class QueryProxy final : public Query {
public:
    std::string_view execute() override {
        if (!target_) {
            target_ = std::make_unique<RealQuery>();
        }
        ++calls_;
        return target_->execute();
    }
    int calls() const { return calls_; }

private:
    std::unique_ptr<Query> target_;
    int calls_ = 0;
};

int main() {
    QueryProxy proxy;
    Query& query = proxy;
    std::cout << "before: constructions=" << RealQuery::construction_count()
              << ", calls=" << proxy.calls() << '\n';
    std::cout << query.execute() << '\n';
    std::cout << "first: constructions=" << RealQuery::construction_count()
              << ", calls=" << proxy.calls() << '\n';
    std::cout << query.execute() << '\n';
    std::cout << "second: constructions=" << RealQuery::construction_count()
              << ", calls=" << proxy.calls() << '\n';
}
