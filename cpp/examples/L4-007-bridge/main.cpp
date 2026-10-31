#include <iostream>
#include <memory>
#include <string>
#include <string_view>
#include <utility>

class Source {
public:
    virtual ~Source() = default;
    virtual std::string_view read() const = 0;
};

class FileSource final : public Source {
public:
    std::string_view read() const override { return "file"; }
};

class MemorySource final : public Source {
public:
    std::string_view read() const override { return "memory"; }
};

class Report {
public:
    explicit Report(std::shared_ptr<const Source> source) : source_(std::move(source)) {}
    virtual ~Report() = default;
    virtual std::string render() const = 0;

protected:
    const Source& source() const { return *source_; }

private:
    std::shared_ptr<const Source> source_;
};

class TextReport final : public Report {
public:
    using Report::Report;
    std::string render() const override { return "text/" + std::string(source().read()); }
};

class JsonReport final : public Report {
public:
    using Report::Report;
    std::string render() const override { return "json/" + std::string(source().read()); }
};

int main() {
    const std::shared_ptr<const Source> file = std::make_shared<FileSource>();
    const std::shared_ptr<const Source> memory = std::make_shared<MemorySource>();
    const std::unique_ptr<Report> reports[] = {
        std::make_unique<TextReport>(file), std::make_unique<TextReport>(memory),
        std::make_unique<JsonReport>(file), std::make_unique<JsonReport>(memory)};
    for (const auto& report : reports) {
        std::cout << report->render() << '\n';
    }
}
