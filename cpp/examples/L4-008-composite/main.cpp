#include <iostream>
#include <memory>
#include <string>
#include <utility>
#include <vector>

class Node {
public:
    virtual ~Node() = default;
    virtual void render(std::ostream& out, std::size_t depth) const = 0;
};

class Leaf final : public Node {
public:
    explicit Leaf(std::string text) : text_(std::move(text)) {}
    void render(std::ostream& out, std::size_t depth) const override {
        out << std::string(depth * 2, ' ') << text_ << '\n';
    }

private:
    std::string text_;
};

class Group final : public Node {
public:
    void add_child(std::unique_ptr<Node> child) { children_.push_back(std::move(child)); }
    void render(std::ostream& out, std::size_t depth) const override {
        for (const auto& child : children_) {
            child->render(out, depth + 1);
        }
    }

private:
    std::vector<std::unique_ptr<Node>> children_;
};

int main() {
    auto root = std::make_unique<Group>();
    root->add_child(std::make_unique<Leaf>("alpha"));
    auto branch = std::make_unique<Group>();
    branch->add_child(std::make_unique<Leaf>("beta"));
    auto nested = std::make_unique<Group>();
    nested->add_child(std::make_unique<Leaf>("gamma"));
    branch->add_child(std::move(nested));
    root->add_child(std::move(branch));
    root->add_child(std::make_unique<Leaf>("delta"));
    const std::unique_ptr<Node> tree = std::move(root);
    tree->render(std::cout, 0);
}
