CC ?= gcc
CPPFLAGS ?= -D_POSIX_C_SOURCE=200809L -D_DEFAULT_SOURCE -Isrc
# L2-010-strict-warnings: compile as C17 and treat all requested warnings as errors.
CFLAGS ?= -std=c17 -O2 -Wall -Wextra -Werror -pedantic
LDFLAGS ?=

# L2-001-multifile-build: link the project's separate implementation units together.
SOURCES := src/main.c src/net/server.c src/pool/pool.c src/log/log.c src/http/http.c
OBJECTS := $(SOURCES:.c=.o)
TARGET := devbox-c-server

.PHONY: all clean test

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(CC) $(LDFLAGS) -o $@ $(OBJECTS)

src/%.o: src/%.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -MMD -MP -c $< -o $@

test: $(TARGET)
	bash test/smoke.sh
	./$(TARGET) --selftest

clean:
	rm -f $(OBJECTS) $(OBJECTS:.o=.d) $(TARGET)

# L2-002-makefile-incremental: generated dependency files make header edits rebuild objects.
-include $(OBJECTS:.o=.d)
