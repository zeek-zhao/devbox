package devbox.rest;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.locks.ReentrantLock;

final class RestService implements Api {
    private final Map<Integer, Item> items = new ConcurrentHashMap<>(); // L1-017-collection-selection
    private final ReentrantLock transaction = new ReentrantLock();
    private final Counter requests = new Counter();
    private int nextId = 1;
    private volatile boolean ready; // L1-031-volatile-publication

    @FunctionalInterface
    private interface Route { Reply apply(Request request); } // L1-011-functional-interface

    private final Map<String, Route> routes = Map.of(
            "GET /healthz", request -> new Text(200, "{\"status\":\"ok\"}", true),
            "GET /metrics", request -> new Text(200, "requests_total " + requests.value() + "\n", false),
            "GET /items", request -> new Many(snapshot()),
            "POST /items", this::create);

    private sealed interface Reply permits One, Many, Text, Failure {}
    private record One(int status, Item item) implements Reply {}
    private record Many(List<Item> items) implements Reply {
        Many { items = List.copyOf(items); }
    }
    private record Text(int status, String body, boolean json) implements Reply {}
    private record Failure(int status, String message) implements Reply {}

    @Override public Result handle(Request request) {
        Objects.requireNonNull(request, "request");
        requests.increment();
        transaction.lock();
        try {
            Reply reply;
            try {
                Route route = routes.get(request.method() + " " + request.path());
                reply = route == null ? itemRoute(request) : route.apply(request);
            } catch (ValidationException e) {
                reply = new Failure(400, e.getMessage());
            }
            Result result = encode(reply);
            ready = true;
            return result;
        } finally {
            transaction.unlock(); // L1-025-finally-return
        }
    }

    @Override public boolean ready() { return ready; }

    private Reply create(Request request) {
        String name = Json.parseName(request.body());
        int id = nextId;
        nextId = Math.addExact(nextId, 1); // L1-006-numeric-boxing
        Item item = new Item(id, name);
        items.put(id, item);
        return new One(201, item);
    }

    private Reply itemRoute(Request request) {
        if (request.path().equals("/items") || request.path().equals("/healthz")
                || request.path().equals("/metrics")) return new Failure(405, "method not allowed");
        if (!request.path().startsWith("/items/")) return new Failure(404, "route not found");
        String suffix = request.path().substring("/items/".length());
        if (!suffix.matches("[1-9][0-9]{0,9}")) throw new ValidationException("invalid id");
        int id;
        try {
            id = Integer.parseInt(suffix);
        } catch (NumberFormatException e) {
            throw new ValidationException("id out of range", e);
        }
        return switch (Verb.parse(request.method())) {
            case GET -> find(id).<Reply>map(item -> new One(200, item))
                    .orElseGet(() -> new Failure(404, "item not found")); // L1-021-optional-fallback
            case PUT -> {
                String name = Json.parseName(request.body());
                if (!items.containsKey(id)) yield new Failure(404, "item not found");
                Item item = new Item(id, name);
                items.put(id, item);
                yield new One(200, item);
            }
            case DELETE -> items.remove(id) == null
                    ? new Failure(404, "item not found") : new Text(204, "", true);
            case OTHER -> new Failure(405, "method not allowed");
        };
    }

    private enum Verb {
        GET, PUT, DELETE, OTHER;
        static Verb parse(String method) {
            return switch (method) { // L1-012-enum-switch
                case "GET" -> GET;
                case "PUT" -> PUT;
                case "DELETE" -> DELETE;
                default -> { yield OTHER; }
            };
        }
    }

    private Optional<Item> find(int id) { return Optional.ofNullable(items.get(id)); }

    @Override public List<Item> snapshot() {
        transaction.lock();
        try {
            List<Item> copy = new ArrayList<>(items.values()); // L1-014-generic-safety
            copy.sort(Comparator.comparingInt(Item::id)); // L1-018-iteration-views
            return List.copyOf(copy);
        } finally {
            transaction.unlock();
        }
    }

    private static Result encode(Reply reply) {
        return switch (reply) { // L1-027-sealed-pattern-switch
            case One one -> json(one.status(), Json.item(one.item()));
            case Many many -> json(200, Json.items(many.items()));
            case Text text -> new Result(text.status(), text.json()
                    ? "application/json; charset=utf-8" : "text/plain; charset=utf-8", text.body());
            case Failure failure -> json(failure.status(), "{\"error\":" + Json.quote(failure.message()) + "}");
        };
    }

    private static Result json(int status, String body) {
        return new Result(status, "application/json; charset=utf-8", body);
    }

    private static final class Counter {
        private long count;
        synchronized void increment() { count = Math.addExact(count, 1); } // L1-030-synchronized-counter
        synchronized long value() { return count; }
    }
}
