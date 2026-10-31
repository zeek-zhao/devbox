#include <iostream>
#include <memory>
#include <string>
#include <utility>

class LegacyQuery {
public:
    explicit LegacyQuery(std::string result) : result_(std::move(result)) {}
    std::string fetch_record() const { return "legacy: " + result_; }

private:
    std::string result_;
};

class Query {
public:
    virtual ~Query() = default;
    virtual std::string execute() const = 0;
};

class QueryAdapter final : public Query {
public:
    explicit QueryAdapter(LegacyQuery legacy) : legacy_(std::move(legacy)) {}
    std::string execute() const override { return legacy_.fetch_record(); }

private:
    LegacyQuery legacy_;
};

int main() {
    const std::unique_ptr<Query> first =
        std::make_unique<QueryAdapter>(LegacyQuery{"record-7"});
    const std::unique_ptr<Query> second =
        std::make_unique<QueryAdapter>(LegacyQuery{"record-9"});
    std::cout << first->execute() << '\n';
    std::cout << second->execute() << '\n';
}
