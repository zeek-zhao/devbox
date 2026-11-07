#include <iostream>
#include <stdexcept>
#include <string>

// 异常 try/catch：catch 子句自上而下匹配，第一个「能接住」的子句生效。
// 派生类必须排在基类前面，否则会被基类子句截胡，派生分支永远不可达。

class ParseError : public std::runtime_error {
public:
    explicit ParseError(const std::string& token)
        : std::runtime_error("parse failed"), token_(token) {}
    const std::string& token() const { return token_; }

private:
    std::string token_;
};

class SchemaError : public std::runtime_error {
public:
    explicit SchemaError(const std::string& field)
        : std::runtime_error("schema failed"), field_(field) {}
    const std::string& field() const { return field_; }

private:
    std::string field_;
};

static void parse(const std::string& token) {
    throw ParseError(token);
}
static void validate(const std::string& field) {
    throw SchemaError(field);
}

int main() {
    // 错误示范（编译不可达，写不出来）：把 catch (const std::runtime_error&) 放在
    // catch (const ParseError&) 前面，编译器会直接警告/报错「handler unreachable」。

    // 正确顺序：最派生 → 最基类。
    try {
        parse("<name>");
    } catch (const ParseError& e) {
        std::cout << "parse branch: " << e.what() << " token=" << e.token() << '\n';
    } catch (const std::runtime_error& e) {
        std::cout << "base branch: " << e.what() << '\n';
    }

    try {
        validate("age");
    } catch (const ParseError& e) {
        std::cout << "parse branch: " << e.what() << '\n';
    } catch (const SchemaError& e) {
        std::cout << "schema branch: " << e.what() << " field=" << e.field() << '\n';
    } catch (const std::exception& e) {
        std::cout << "std branch: " << e.what() << '\n';
    }

    // 基类引用捕获派生对象：what() 是虚函数，拿到的是派生类的消息。
    try {
        throw ParseError("<id>");
    } catch (const std::exception& e) {
        std::cout << "sliced-free catch: " << e.what() << '\n';
    }

    // catch (...) 兜底，但拿不到异常对象，只作最后防线。
    try {
        throw 42; // 非异常类型的值抛出
    } catch (...) {
        std::cout << "catch-all: unknown throwable\n";
    }
    return 0;
}
