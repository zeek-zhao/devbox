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
    private final Map<Integer, Item> items =
            new ConcurrentHashMap<>(); // L1-017-collection-selection
    private final ReentrantLock transaction = new ReentrantLock();
    private final Counter requests = new Counter();
    private final RequestEvents events = new RequestEvents(List.of(requests));
    private int nextId = 1;
    private volatile boolean ready; // L1-031-volatile-publication

    @FunctionalInterface
    interface Route {
        Reply apply(Request request);
    } // L1-011-functional-interface

    // L4-008-composite: groups and leaves resolve through the same Router interface.
    private final Router routes =
            new RouteGroup(
                    List.of(
                            new RouteGroup(
                                    List.of(
                                            new ExactRoute(
                                                    "GET",
                                                    "/healthz",
                                                    request ->
                                                            new Text(
                                                                    200,
                                                                    "{\"status\":\"ok\"}",
                                                                    true)),
                                            new ExactRoute(
                                                    "GET",
                                                    "/metrics",
                                                    request ->
                                                            new Text(
                                                                    200,
                                                                    "requests_total "
                                                                            + requests.value()
                                                                            + "\n",
                                                                    false)))),
                            new RouteGroup(
                                    List.of(
                                            new ExactRoute(
                                                    "GET",
                                                    "/items",
                                                    request -> new Many(snapshot())),
                                            new ExactRoute("POST", "/items", new CreateRoute()))),
                            request -> Optional.of(this::itemRoute)));
    private final Route dispatch =
            new ValidatedRoute(
                    request ->
                            routes.resolve(request)
                                    .orElseThrow()
                                    .apply(request)); // L4-021-strategy

    sealed interface Reply permits One, Many, Text, Failure {}

    record One(int status, Item item) implements Reply {}

    private record Many(List<Item> items) implements Reply {
        Many {
            items = List.copyOf(items);
        }
    }

    record Text(int status, String body, boolean json) implements Reply {}

    record Failure(int status, String message) implements Reply {}

    interface Router {
        Optional<Route> resolve(Request request);
    }

    record ExactRoute(String method, String path, Route route) implements Router {
        @Override
        public Optional<Route> resolve(Request request) {
            return method.equals(request.method()) && path.equals(request.path())
                    ? Optional.of(route)
                    : Optional.empty();
        }
    }

    record RouteGroup(List<Router> children) implements Router {
        RouteGroup {
            children = List.copyOf(children);
        }

        @Override
        public Optional<Route> resolve(Request request) {
            for (Router child : children) {
                Optional<Route> route = child.resolve(request);
                if (route.isPresent()) return route;
            }
            return Optional.empty();
        }
    }

    // L4-009-decorator: retain Route's contract while translating input failures.
    record ValidatedRoute(Route delegate) implements Route {
        @Override
        public Reply apply(Request request) {
            try {
                return delegate.apply(request);
            } catch (ValidationException e) {
                return new Failure(400, e.getMessage());
            }
        }
    }

    @FunctionalInterface
    interface RequestObserver {
        void accepted(Request request);
    }

    // L4-019-observer: request delivery is separate from metric accumulation.
    record RequestEvents(List<RequestObserver> observers) {
        RequestEvents {
            observers = List.copyOf(observers);
        }

        void publish(Request request) {
            for (RequestObserver observer : observers) observer.accepted(request);
        }
    }

    @Override
    public Result handle(Request request) {
        Objects.requireNonNull(request, "request");
        events.publish(request);
        transaction.lock();
        try {
            Reply reply = dispatch.apply(request);
            Result result = encode(reply);
            ready = true;
            return result;
        } finally {
            transaction.unlock(); // L1-025-finally-return
        }
    }

    @Override
    public boolean ready() {
        return ready;
    }

    // L4-022-template-method: validate, mutate, then manufacture a success reply.
    abstract static class NameRoute implements Route {
        @Override
        public final Reply apply(Request request) {
            String name = Json.parseName(request.body());
            return save(name)
                    .<Reply>map(this::success)
                    .orElseGet(() -> new Failure(404, "item not found"));
        }

        abstract Optional<Item> save(String name);

        abstract Reply success(Item item); // L4-002-factory-method
    }

    private final class CreateRoute extends NameRoute {
        @Override
        Optional<Item> save(String name) {
            int id = nextId;
            nextId = Math.addExact(nextId, 1); // L1-006-numeric-boxing
            Item item = new Item(id, name);
            items.put(id, item);
            return Optional.of(item);
        }

        @Override
        One success(Item item) {
            return new One(201, item);
        }
    }

    private final class UpdateRoute extends NameRoute {
        private final int id;

        UpdateRoute(int id) {
            this.id = id;
        }

        @Override
        Optional<Item> save(String name) {
            if (!items.containsKey(id)) return Optional.empty();
            Item item = new Item(id, name);
            items.put(id, item);
            return Optional.of(item);
        }

        @Override
        One success(Item item) {
            return new One(200, item);
        }
    }

    private Reply itemRoute(Request request) {
        if (request.path().equals("/items")
                || request.path().equals("/healthz")
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
            case GET ->
                    find(id).<Reply>map(item -> new One(200, item))
                            .orElseGet(
                                    () ->
                                            new Failure(
                                                    404,
                                                    "item not found")); // L1-021-optional-fallback
            case PUT -> new UpdateRoute(id).apply(request);
            case DELETE ->
                    items.remove(id) == null
                            ? new Failure(404, "item not found")
                            : new Text(204, "", true);
            case OTHER -> new Failure(405, "method not allowed");
        };
    }

    private enum Verb {
        GET,
        PUT,
        DELETE,
        OTHER;

        static Verb parse(String method) {
            return switch (method) { // L1-012-enum-switch
                case "GET" -> GET;
                case "PUT" -> PUT;
                case "DELETE" -> DELETE;
                default -> {
                    yield OTHER;
                }
            };
        }
    }

    private Optional<Item> find(int id) {
        return Optional.ofNullable(items.get(id));
    }

    @Override
    public List<Item> snapshot() {
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
            case Text text ->
                    new ResultBuilder()
                            .status(text.status())
                            .contentType(
                                    text.json()
                                            ? "application/json; charset=utf-8"
                                            : "text/plain; charset=utf-8")
                            .body(text.body())
                            .build();
            case Failure failure ->
                    json(failure.status(), "{\"error\":" + Json.quote(failure.message()) + "}");
        };
    }

    private static Result json(int status, String body) {
        return new ResultBuilder()
                .status(status)
                .contentType("application/json; charset=utf-8")
                .body(body)
                .build();
    }

    private static final class Counter implements RequestObserver {
        private long count;

        @Override
        public void accepted(Request request) {
            increment();
        }

        synchronized void increment() {
            count = Math.addExact(count, 1);
        } // L1-030-synchronized-counter

        synchronized long value() {
            return count;
        }
    }
}
