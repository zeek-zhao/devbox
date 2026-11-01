package devbox.rest;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.atomic.AtomicInteger;

/** Assertions for the patterns used by the production request pipeline. */
public final class PatternTest {
    private PatternTest() {}

    /** Checks dispatch, mutation ordering, observation and wire-envelope construction. */
    public static void run() {
        if (!PatternTest.class.desiredAssertionStatus()) {
            throw new IllegalStateException("PatternTest requires -ea");
        }
        routing();
        decoration();
        observation();
        construction();
        templateFactory();
        mutations();
        System.out.println("[pass] java patterns OK (8 integrated)");
    }

    private static void routing() {
        Api.Request request = new Api.Request("GET", "/items", "");
        RestService.Route list = input -> new RestService.Text(200, "list", true);
        RestService.Route create = input -> new RestService.Text(201, "create", true);
        List<RestService.Router> leaves = new ArrayList<>();
        leaves.add(new RestService.ExactRoute("GET", "/items", list));
        leaves.add(new RestService.ExactRoute("POST", "/items", create));
        RestService.Router resource = new RestService.RouteGroup(leaves);
        leaves.clear();
        RestService.Router root =
                new RestService.RouteGroup(
                        List.of(new RestService.RouteGroup(List.of()), resource));
        assert root.resolve(request).orElseThrow() == list;
        assert root.resolve(request)
                .orElseThrow()
                .apply(request)
                .equals(new RestService.Text(200, "list", true));
        Api.Request post = new Api.Request("POST", "/items", "");
        assert root.resolve(post).orElseThrow() == create;
        assert root.resolve(post)
                .orElseThrow()
                .apply(post)
                .equals(new RestService.Text(201, "create", true));
        assert root.resolve(new Api.Request("GET", "/unknown", "")).isEmpty();
        assert root.resolve(new Api.Request("PUT", "/items", "")).isEmpty();
        RestService.Router fallback = input -> Optional.of(create);
        assert new RestService.RouteGroup(List.of(root, fallback)).resolve(request).orElseThrow()
                == list;
    }

    private static void decoration() {
        Api.Request request = new Api.Request("POST", "/items", "");
        AtomicInteger calls = new AtomicInteger();
        RestService.Reply success = new RestService.One(201, new Api.Item(1, "Ada"));
        RestService.Route route =
                input -> {
                    calls.incrementAndGet();
                    return success;
                };
        assert new RestService.ValidatedRoute(route).apply(request) == success;
        assert calls.get() == 1;
        RestService.Route invalid =
                input -> {
                    throw new ValidationException("bad name");
                };
        assert new RestService.ValidatedRoute(invalid)
                .apply(request)
                .equals(new RestService.Failure(400, "bad name"));
        RestService.Route broken =
                input -> {
                    throw new IllegalStateException("broken handler");
                };
        reject(
                IllegalStateException.class,
                () -> new RestService.ValidatedRoute(broken).apply(request));
    }

    private static void observation() {
        Api.Request request = new Api.Request("GET", "/healthz", "");
        AtomicInteger first = new AtomicInteger();
        AtomicInteger second = new AtomicInteger();
        List<RestService.RequestObserver> listeners = new ArrayList<>();
        listeners.add(
                input -> {
                    assert input == request;
                    first.incrementAndGet();
                });
        listeners.add(input -> second.incrementAndGet());
        RestService.RequestEvents events = new RestService.RequestEvents(listeners);
        listeners.clear();
        events.publish(request);
        events.publish(request);
        assert first.get() == 2 && second.get() == 2;
        RestService.RequestEvents broken =
                new RestService.RequestEvents(
                        List.of(
                                input -> {
                                    throw new IllegalStateException("observer failed");
                                }));
        reject(IllegalStateException.class, () -> broken.publish(request));
    }

    private static void construction() {
        Api.Result json =
                new ResultBuilder()
                        .body("{}")
                        .contentType("application/json; charset=utf-8")
                        .status(200)
                        .build();
        assert json.equals(new Api.Result(200, "application/json; charset=utf-8", "{}"));
        ResultBuilder builder =
                new ResultBuilder()
                        .status(204)
                        .contentType("application/json; charset=utf-8")
                        .body("");
        Api.Result deleted = builder.build();
        assert deleted.body().isEmpty();
        builder.status(200).body("changed");
        assert deleted.status() == 204 && deleted.body().isEmpty();
        reject(IllegalArgumentException.class, () -> builder.contentType("text/plain\r\nx"));
        assert builder.build().contentType().equals("application/json; charset=utf-8");
        assert json.body().equals("{}");
        reject(IllegalStateException.class, () -> new ResultBuilder().build());
        reject(IllegalStateException.class, () -> new ResultBuilder().status(200).body("").build());
        reject(
                IllegalStateException.class,
                () -> new ResultBuilder().status(200).contentType("text/plain").build());
        reject(IllegalArgumentException.class, () -> new ResultBuilder().status(99));
        reject(IllegalArgumentException.class, () -> new ResultBuilder().status(600));
        reject(
                IllegalArgumentException.class,
                () -> new ResultBuilder().contentType("text/plain\nx"));
        reject(IllegalArgumentException.class, () -> new ResultBuilder().contentType(" "));
        reject(NullPointerException.class, () -> new ResultBuilder().body(null));
        reject(NullPointerException.class, () -> new ResultBuilder().contentType(null));
        reject(
                IllegalStateException.class,
                () ->
                        new ResultBuilder()
                                .status(204)
                                .contentType("text/plain")
                                .body("not empty")
                                .build());
    }

    private static void mutations() {
        Api api = Api.create();
        assert call(api, "POST", "/items", "{}").status() == 400;
        assert api.snapshot().isEmpty();
        Api.Result created = call(api, "POST", "/items", Json.name("Ada"));
        assert created.status() == 201 && created.body().equals("{\"id\":1,\"name\":\"Ada\"}");
        assert call(api, "PUT", "/items/1", "{}").status() == 400;
        assert api.snapshot().equals(List.of(new Api.Item(1, "Ada")));
        Api.Result updated = call(api, "PUT", "/items/1", Json.name("Bob"));
        assert updated.status() == 200 && updated.body().equals("{\"id\":1,\"name\":\"Bob\"}");
        assert call(api, "PUT", "/items/99", "{}").status() == 400;
        assert call(api, "PUT", "/items/99", Json.name("Missing")).status() == 404;
        assert call(api, "POST", "/items", Json.name("Second"))
                .body()
                .equals("{\"id\":2,\"name\":\"Second\"}");
        assert api.snapshot().equals(List.of(new Api.Item(1, "Bob"), new Api.Item(2, "Second")));
        assert call(api, "GET", "/items", "")
                .body()
                .equals("[{\"id\":1,\"name\":\"Bob\"},{\"id\":2,\"name\":\"Second\"}]");
        assert call(api, "GET", "/healthz", "").body().equals("{\"status\":\"ok\"}");
        assert call(api, "PATCH", "/items", "").status() == 405;
        assert call(api, "GET", "/missing", "").status() == 404;
        assert call(api, "DELETE", "/items/1", "")
                .equals(new Api.Result(204, "application/json; charset=utf-8", ""));
        reject(NullPointerException.class, () -> api.handle(null));
        assert call(api, "GET", "/metrics", "")
                .equals(new Api.Result(200, "text/plain; charset=utf-8", "requests_total 13\n"));
        assert Api.create().snapshot().isEmpty();
    }

    private static void templateFactory() {
        List<String> steps = new ArrayList<>();
        RestService.NameRoute route =
                new RestService.NameRoute() {
                    @Override
                    Optional<Api.Item> save(String name) {
                        steps.add("save:" + name);
                        return Optional.of(new Api.Item(1, name));
                    }

                    @Override
                    RestService.Reply success(Api.Item item) {
                        steps.add("reply:" + item.name());
                        return new RestService.Text(200, item.name(), false);
                    }
                };
        Api.Request invalid = new Api.Request("POST", "/items", "{}");
        reject(ValidationException.class, () -> route.apply(invalid));
        assert steps.isEmpty();
        assert route.apply(new Api.Request("POST", "/items", Json.name("Ada")))
                .equals(new RestService.Text(200, "Ada", false));
        assert steps.equals(List.of("save:Ada", "reply:Ada"));
    }

    private static Api.Result call(Api api, String method, String path, String body) {
        return api.handle(new Api.Request(method, path, body));
    }

    private static void reject(Class<? extends RuntimeException> type, Runnable action) {
        try {
            action.run();
        } catch (RuntimeException e) {
            if (type.isInstance(e)) return;
            throw new AssertionError("expected " + type.getSimpleName() + ", got " + e, e);
        }
        throw new AssertionError("expected " + type.getSimpleName());
    }
}
