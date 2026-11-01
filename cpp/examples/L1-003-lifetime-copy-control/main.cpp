#include <iostream>

class Resource {
public:
    explicit Resource(int value) : value_{new int{value}} {
        std::cout << "construct " << *value_ << '\n';
    }

    Resource(const Resource& other) : value_{new int{*other.value_}} {
        std::cout << "copy-construct " << *value_ << '\n';
    }

    Resource& operator=(const Resource& other) {
        if (this != &other) {
            int* replacement = new int{*other.value_};
            delete value_;
            value_ = replacement;
            std::cout << "copy-assign " << *value_ << '\n';
        }
        return *this;
    }

    ~Resource() {
        std::cout << "destroy " << *value_ << '\n';
        delete value_;
    }

    void set(int value) { *value_ = value; }
    int get() const { return *value_; }

private:
    int* value_;
};

int main() {
    {
        Resource original{7};
        Resource copied{original};
        Resource assigned{3};
        assigned = copied;
        assigned.set(9);
        std::cout << "values: original=" << original.get() << " copied=" << copied.get()
                  << " assigned=" << assigned.get() << '\n';
    }
}
