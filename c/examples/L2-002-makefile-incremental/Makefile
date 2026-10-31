CC ?= gcc
CFLAGS ?= -std=c17 -Wall -Wextra -Werror
BUILD_DIR ?= build
TARGET = $(BUILD_DIR)/example

.PHONY: all
all: $(TARGET)

$(TARGET): main.c
	mkdir -p "$(BUILD_DIR)"
	$(CC) $(CFLAGS) main.c -o "$@"
