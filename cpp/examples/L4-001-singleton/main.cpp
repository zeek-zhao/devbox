#include <iostream>
#include <type_traits>

class Config {
public:
    static Config& instance() {
        static Config config;
        return config;
    }

    Config(const Config&) = delete;
    Config& operator=(const Config&) = delete;

    void set_count(int count) { count_ = count; }
    int count() const { return count_; }

private:
    Config() = default;
    int count_ = 0;
};

static_assert(!std::is_copy_constructible_v<Config>);
static_assert(!std::is_copy_assignable_v<Config>);

int main() {
    auto& a = Config::instance();
    auto& b = Config::instance();
    std::cout << std::boolalpha << "same instance: " << (&a == &b) << '\n';
    b.set_count(7);
    const auto& c = Config::instance();
    std::cout << "count: " << c.count() << '\n';
}
