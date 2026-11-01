#include <stdio.h>
#include <string.h>

int main(void) {
    const char* source = "toolong";
    char copied[8];
    char truncated[4];
    char safe[5];
    volatile size_t truncated_size = sizeof(truncated);

    printf("strlen=%zu\n", strlen(source));
    strcpy(copied, "ok");
    printf("strcpy=%s\n", copied);
    strncpy(truncated, source, truncated_size);
    printf("strncpy bytes=%c%c%c%c, terminated=%s\n", truncated[0], truncated[1], truncated[2],
           truncated[3], memchr(truncated, '\0', sizeof(truncated)) == NULL ? "no" : "yes");
    strncpy(safe, source, sizeof(safe) - 1);
    safe[sizeof(safe) - 1] = '\0';
    printf("safe strncpy=%s\n", safe);
    return 0;
}
