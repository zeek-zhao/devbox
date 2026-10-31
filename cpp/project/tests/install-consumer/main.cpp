#include <index.h>
#include <index_c.h>

int main() {
    devbox::InvertedIndex index;
    devbox_index_close(nullptr);
    return index.state() == devbox::InvertedIndex::State::empty ? 0 : 1;
}
