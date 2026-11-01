#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

enum { BUCKETS = 17, KEY_COUNT = 100 };

typedef struct node {
    int key;
    int value;
    struct node* next;
} node;

typedef struct table {
    node* buckets[BUCKETS];
    size_t size;
} table;

static size_t hash_key(int key) {
    const unsigned int positive = (unsigned int)key;
    return (size_t)(positive % BUCKETS);
}

static bool insert(table* map, int key, int value) {
    const size_t index = hash_key(key);
    for (node* entry = map->buckets[index]; entry != NULL; entry = entry->next) {
        if (entry->key == key) {
            entry->value = value;
            return true;
        }
    }
    node* entry = malloc(sizeof(*entry));
    if (entry == NULL) {
        return false;
    }
    *entry = (node){key, value, map->buckets[index]};
    map->buckets[index] = entry;
    ++map->size;
    return true;
}

static bool contains(const table* map, int key) {
    for (node* entry = map->buckets[hash_key(key)]; entry != NULL; entry = entry->next) {
        if (entry->key == key) {
            return true;
        }
    }
    return false;
}

static bool erase(table* map, int key) {
    node** link = &map->buckets[hash_key(key)];
    while (*link != NULL) {
        if ((*link)->key == key) {
            node* removed = *link;
            *link = removed->next;
            free(removed);
            --map->size;
            return true;
        }
        link = &(*link)->next;
    }
    return false;
}

static void destroy(table* map) {
    for (size_t i = 0; i < BUCKETS; ++i) {
        node* entry = map->buckets[i];
        while (entry != NULL) {
            node* next = entry->next;
            free(entry);
            entry = next;
        }
    }
}

int main(void) {
    table map = {0};
    for (int key = 0; key < KEY_COUNT; ++key) {
        if (!insert(&map, key, key * 10)) {
            destroy(&map);
            return 1;
        }
    }
    size_t found = 0U;
    for (int key = 0; key < KEY_COUNT; ++key) {
        found += contains(&map, key) ? 1U : 0U;
    }
    size_t missing = 0U;
    for (int key = KEY_COUNT; key < KEY_COUNT + 10; ++key) {
        missing += contains(&map, key) ? 0U : 1U;
    }
    size_t deleted = 0U;
    for (int key = KEY_COUNT / 2; key < KEY_COUNT; ++key) {
        deleted += erase(&map, key) ? 1U : 0U;
    }
    size_t remaining_found = 0U;
    for (int key = 0; key < KEY_COUNT / 2; ++key) {
        remaining_found += contains(&map, key) ? 1U : 0U;
    }
    printf("found=%zu\n", found);
    printf("missing=%zu\n", missing);
    printf("deleted=%zu\n", deleted);
    printf("remaining=%zu\n", map.size);
    printf("remaining_found=%zu\n", remaining_found);
    const bool valid = found == KEY_COUNT && missing == 10U && deleted == KEY_COUNT / 2 &&
                       map.size == 50U && remaining_found == 50U;
    destroy(&map);
    return valid ? 0 : 1;
}
