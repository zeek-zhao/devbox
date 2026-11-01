#include "net/server.h"

#include "http/http.h"
#include "log/log.h"
#include "pool/pool.h"

#include <errno.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <signal.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/epoll.h>
#include <sys/socket.h>
#include <unistd.h>

#define SERVER_MAX_EVENTS 64
#define SERVER_MAX_CONNECTIONS 128U

/* L1-014-enum-values: represent the client's read and write phases explicitly. */
typedef enum { CLIENT_READING = 0, CLIENT_WRITING } client_state_t;

typedef struct client client_t;

struct client {
    int fd;
    client_state_t state;
    http_connection_t http;
    client_t* next;
};

static volatile sig_atomic_t stopping = 0;
static log_ring_t server_log;
static client_t* active_clients = NULL;

static void handle_signal(int signal_number) {
    (void)signal_number;
    stopping = 1;
}

static bool set_nonblocking(int fd) {
    int flags = fcntl(fd, F_GETFL, 0);
    /* L1-012-bitops: preserve existing flags while enabling O_NONBLOCK. */
    return flags >= 0 && fcntl(fd, F_SETFL, flags | O_NONBLOCK) == 0;
}

bool server_parse_port(const char* text, uint16_t* port) {
    if (text == NULL || port == NULL || text[0] == '\0') {
        return false;
    }
    errno = 0;
    char* end = NULL;
    unsigned long value = strtoul(text, &end, 10);
    /* L2-014-errno-handling: reject conversion errors, trailing text, and out-of-range ports. */
    if (errno != 0 || end == text || *end != '\0' || value == 0UL || value > UINT16_MAX) {
        return false;
    }
    /* L1-004-fixed-width-types: narrow only after validating the uint16_t range. */
    *port = (uint16_t)value;
    return true;
}

static void close_client(int epoll_fd, pool_t* clients, client_t* client) {
    (void)epoll_ctl(epoll_fd, EPOLL_CTL_DEL, client->fd, NULL);
    (void)close(client->fd);
    client->fd = -1;
    client_t** link = &active_clients;
    while (*link != NULL && *link != client) {
        link = &(*link)->next;
    }
    if (*link == client) {
        *link = client->next;
    }
    (void)pool_release(clients, client);
}

static bool modify_client_event(int epoll_fd, client_t* client, uint32_t events) {
    struct epoll_event event = {.events = events, .data.ptr = client};
    return epoll_ctl(epoll_fd, EPOLL_CTL_MOD, client->fd, &event) == 0;
}

static void accept_clients(int epoll_fd, int listener, pool_t* clients) {
    for (;;) {
        int fd = accept(listener, NULL, NULL);
        if (fd < 0) {
            if (errno == EINTR) {
                continue;
            }
            if (errno != EAGAIN && errno != EWOULDBLOCK) {
                log_write(&server_log, "accept failed");
            }
            return;
        }
        if (!set_nonblocking(fd)) {
            (void)close(fd);
            continue;
        }
        /* L3-003-memory-pool: reuse a bounded client slot instead of allocating per connection. */
        client_t* client = pool_acquire(clients);
        if (client == NULL) {
            (void)close(fd);
            continue;
        }
        client->fd = fd;
        client->state = CLIENT_READING;
        http_connection_init(&client->http);
        struct epoll_event event = {.events = EPOLLIN | EPOLLRDHUP, .data.ptr = client};
        if (epoll_ctl(epoll_fd, EPOLL_CTL_ADD, fd, &event) < 0) {
            (void)close(fd);
            (void)pool_release(clients, client);
        } else {
            client->next = active_clients;
            active_clients = client;
        }
    }
}

static void read_client(int epoll_fd, pool_t* clients, client_t* client) {
    while (client->http.request_length < sizeof(client->http.request) - 1U) {
        size_t remaining = sizeof(client->http.request) - 1U - client->http.request_length;
        /* L1-007-array-decay: recv receives the request array as a pointer. */
        ssize_t amount =
            recv(client->fd, client->http.request + client->http.request_length, remaining, 0);
        if (amount > 0) {
            client->http.request_length += (size_t)amount;
            client->http.request[client->http.request_length] = '\0';
            if (http_request_complete(client->http.request, client->http.request_length)) {
                if (!http_build_response(&client->http)) {
                    close_client(epoll_fd, clients, client);
                    return;
                }
                client->state = CLIENT_WRITING;
                if (!modify_client_event(epoll_fd, client, EPOLLOUT | EPOLLRDHUP)) {
                    close_client(epoll_fd, clients, client);
                }
                return;
            }
            continue;
        }
        if (amount == 0) {
            close_client(epoll_fd, clients, client);
            return;
        }
        if (errno == EINTR) {
            continue;
        }
        if (errno == EAGAIN || errno == EWOULDBLOCK) {
            return;
        }
        close_client(epoll_fd, clients, client);
        return;
    }
    close_client(epoll_fd, clients, client);
}

static void write_client(int epoll_fd, pool_t* clients, client_t* client) {
    while (client->http.response_offset < client->http.response_length) {
        ssize_t amount =
            send(client->fd, client->http.response + client->http.response_offset,
                 client->http.response_length - client->http.response_offset, MSG_NOSIGNAL);
        if (amount > 0) {
            client->http.response_offset += (size_t)amount;
            continue;
        }
        if (amount < 0 && errno == EINTR) {
            continue;
        }
        if (amount < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) {
            return;
        }
        close_client(epoll_fd, clients, client);
        return;
    }
    close_client(epoll_fd, clients, client);
}

static int create_listener(uint16_t port) {
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    if (fd < 0) {
        return -1;
    }
    int enabled = 1;
    if (setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &enabled, sizeof(enabled)) < 0 ||
        !set_nonblocking(fd)) {
        (void)close(fd);
        return -1;
    }
    /* L1-019-compound-literals: construct the listener address value inline. */
    /* L1-018-initializers: designate address fields explicitly. */
    struct sockaddr_in address = (struct sockaddr_in){
        .sin_family = AF_INET,
        .sin_addr.s_addr = htonl(INADDR_LOOPBACK),
        .sin_port = htons(port),
    };
    if (bind(fd, (struct sockaddr*)&address, sizeof(address)) < 0 ||
        listen(fd, (int)SERVER_MAX_CONNECTIONS) < 0) {
        (void)close(fd);
        return -1;
    }
    return fd;
}

int server_run(uint16_t port) {
    stopping = 0;
    active_clients = NULL;
    log_init(&server_log);
    struct sigaction action = {.sa_handler = handle_signal};
    (void)sigemptyset(&action.sa_mask);
    if (sigaction(SIGINT, &action, NULL) < 0 || sigaction(SIGTERM, &action, NULL) < 0) {
        perror("sigaction");
        return 1;
    }

    int listener = create_listener(port);
    if (listener < 0) {
        perror("listen");
        return 1;
    }
    int epoll_fd = epoll_create1(EPOLL_CLOEXEC);
    if (epoll_fd < 0) {
        perror("epoll_create1");
        (void)close(listener);
        return 1;
    }
    /* L1-009-struct-layout: size each fixed pool slot for the complete client structure. */
    pool_t* clients = pool_create(sizeof(client_t), SERVER_MAX_CONNECTIONS);
    if (clients == NULL) {
        perror("pool_create");
        /* L1-022-memory-leak-pattern: release descriptors acquired before pool creation failed. */
        (void)close(epoll_fd);
        (void)close(listener);
        return 1;
    }
    struct epoll_event listener_event = {.events = EPOLLIN, .data.ptr = NULL};
    if (epoll_ctl(epoll_fd, EPOLL_CTL_ADD, listener, &listener_event) < 0) {
        perror("epoll_ctl");
        pool_destroy(clients);
        (void)close(epoll_fd);
        (void)close(listener);
        return 1;
    }

    while (!stopping) {
        struct epoll_event events[SERVER_MAX_EVENTS];
        int count = epoll_wait(epoll_fd, events, SERVER_MAX_EVENTS, 500);
        if (count < 0) {
            if (errno == EINTR) {
                continue;
            }
            perror("epoll_wait");
            stopping = 1;
            break;
        }
        for (int i = 0; i < count; ++i) {
            if (events[i].data.ptr == NULL) {
                accept_clients(epoll_fd, listener, clients);
                continue;
            }
            client_t* client = events[i].data.ptr;
            if ((events[i].events & (EPOLLERR | EPOLLHUP)) != 0U) {
                close_client(epoll_fd, clients, client);
            } else if (client->state == CLIENT_READING) {
                read_client(epoll_fd, clients, client);
            } else {
                write_client(epoll_fd, clients, client);
            }
        }
    }

    (void)close(listener);
    while (active_clients != NULL) {
        close_client(epoll_fd, clients, active_clients);
    }
    log_write(&server_log, "server stopped");
    log_flush(&server_log);
    pool_destroy(clients);
    (void)close(epoll_fd);
    return 0;
}
