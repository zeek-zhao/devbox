#include <iostream>
#include <memory>

struct Releaser {
    const char* label;

    void operator()(int* resource) const {
        delete resource;
        std::cout << "release: " << label << '\n';
    }
};

class Resource {
public:
    explicit Resource(const char* label) : handle_{new int{1}, Releaser{label}} {
        std::cout << "acquire: " << label << '\n';
    }

private:
    std::unique_ptr<int, Releaser> handle_;
};

int main() {
    { Resource normal{"normal"}; }

    try {
        Resource exceptional{"exception"};
        throw 1;
    } catch (int) {
        std::cout << "caught: exception\n";
    }
}
