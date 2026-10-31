#include <stddef.h>
#include <stdio.h>

static size_t comparisons;

static int median_of_three(int left, int middle, int right) {
    ++comparisons;
    if (left < middle) {
        ++comparisons;
        if (middle < right) {
            return middle;
        }
        ++comparisons;
        return left < right ? right : left;
    }
    ++comparisons;
    if (left < right) {
        return left;
    }
    ++comparisons;
    return middle < right ? right : middle;
}

static void partition(int* values, size_t low, size_t high, int pivot, size_t* less_end,
                      size_t* greater_start) {
    size_t less = low;
    size_t current = low;
    size_t greater = high;
    while (current < greater) {
        ++comparisons;
        if (values[current] < pivot) {
            const int temporary = values[current];
            values[current] = values[less];
            values[less++] = temporary;
            ++current;
        } else {
            ++comparisons;
            if (values[current] > pivot) {
                const int temporary = values[current];
                values[current] = values[--greater];
                values[greater] = temporary;
            } else {
                ++current;
            }
        }
    }
    *less_end = less;
    *greater_start = greater;
}

static int quickselect(int* values, size_t count, size_t target) {
    size_t low = 0U;
    size_t high = count;
    while (high - low > 1U) {
        const size_t middle = low + (high - low) / 2U;
        const int pivot = median_of_three(values[low], values[middle], values[high - 1U]);
        size_t less_end = 0U;
        size_t greater_start = 0U;
        partition(values, low, high, pivot, &less_end, &greater_start);
        if (target < less_end) {
            high = less_end;
        } else if (target >= greater_start) {
            low = greater_start;
        } else {
            return pivot;
        }
    }
    return values[low];
}

int main(void) {
    int values[] = {12, 3, 5, 7, 4, 19, 26, 8, 1, 15, 2, 9, 6, 11, 10};
    const size_t target = 7U;
    const int selected = quickselect(values, sizeof(values) / sizeof(values[0]), target);
    printf("k=%zu value=%d\ncomparisons=%zu\n", target, selected, comparisons);
    return selected == 8 ? 0 : 1;
}
