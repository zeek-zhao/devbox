#include <iostream>
#include <stdexcept>
#include <string>
#include <utility>

struct Request {
    std::string query;
    int limit;
    std::string format;
};

class RequestBuilder {
public:
    RequestBuilder& query(std::string value) {
        query_ = std::move(value);
        return *this;
    }
    RequestBuilder& limit(int value) {
        limit_ = value;
        return *this;
    }
    RequestBuilder& format(std::string value) {
        format_ = std::move(value);
        return *this;
    }
    Request build() const {
        if (query_.empty()) {
            throw std::invalid_argument("query is required");
        }
        if (limit_ <= 0) {
            throw std::invalid_argument("limit must be positive");
        }
        return {query_, limit_, format_};
    }

private:
    std::string query_;
    int limit_ = 10;
    std::string format_ = "text";
};

int main() {
    RequestBuilder builder;
    const Request request = builder.query("cpp").limit(3).format("json").build();
    builder.query("changed");
    std::cout << "request: " << request.query << ", " << request.limit
              << ", " << request.format << '\n';
    try {
        const auto invalid = RequestBuilder{}.limit(3).format("json").build();
        std::cerr << "unexpected success: " << invalid.query << '\n';
        return 1;
    } catch (const std::invalid_argument& error) {
        std::cout << "build error: " << error.what() << '\n';
    }
}
