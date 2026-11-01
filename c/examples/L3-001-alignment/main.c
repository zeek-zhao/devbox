#include <stddef.h>
#include <stdint.h>
#include <stdio.h>

int main(void) {
    _Alignas(16) unsigned char storage[16];
    const uintptr_t address = (uintptr_t)(void*)storage;

    printf("_Alignof(int)=%zu\n", _Alignof(int));
    printf("_Alignof(double)=%zu\n", _Alignof(double));
    printf("_Alignof(max_align_t)=%zu\n", _Alignof(max_align_t));
    printf("_Alignas(16) address aligned=%s\n", address % 16U == 0U ? "yes" : "no");
    return 0;
}
