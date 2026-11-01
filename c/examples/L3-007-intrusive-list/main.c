#include <stddef.h>
#include <stdio.h>

#define container_of(pointer, type, member)                                                        \
    ((type*)((unsigned char*)(pointer) - offsetof(type, member)))

typedef struct list_node {
    struct list_node* next;
} list_node;

typedef struct item {
    int id;
    list_node link;
} item;

int main(void) {
    item first = {10, {NULL}};
    item second = {20, {NULL}};
    item third = {30, {NULL}};
    first.link.next = &second.link;
    second.link.next = &third.link;

    printf("ids=");
    list_node* node = &first.link;
    while (node != NULL) {
        const item* current = container_of(node, item, link);
        printf("%s%d", node == &first.link ? "" : ",", current->id);
        node = node->next;
    }
    printf("\nnode_offset=%zu\n", offsetof(item, link));
    return 0;
}
