#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int api_create_message(int value, char **out_message) {
  if (out_message == NULL) {
    return 1;
  }
  *out_message = NULL;

  char buffer[32];
  const int written = snprintf(buffer, sizeof(buffer), "value=%d", value);
  if (written < 0 || (size_t)written >= sizeof(buffer)) {
    return 2;
  }

  char *message = malloc((size_t)written + 1U);
  if (message == NULL) {
    return 3;
  }
  memcpy(message, buffer, (size_t)written + 1U);
  *out_message = message;
  return 0;
}
