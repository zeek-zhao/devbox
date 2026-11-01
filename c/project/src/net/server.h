#ifndef DEVBOX_C_SERVER_H
#define DEVBOX_C_SERVER_H

#include <stdbool.h>
#include <stdint.h>

int server_run(uint16_t port);
bool server_parse_port(const char* text, uint16_t* port);

#endif
