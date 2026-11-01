import devbox.rest.Api;
import devbox.rest.HttpApp;
import devbox.rest.Json;
import devbox.rest.PatternTest;
import devbox.rest.SelfCheck;
import devbox.rest.Snapshot;
import devbox.rest.ValidationException;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.PrintStream;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Objects;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;

/** Integration assertions; failures always escape main and exit nonzero. */
public final class SelfTest {
    private SelfTest() {}

    public static void main(String[] args) throws Exception {
        boolean assertions = false;
        assert assertions = true; // L2-005-assert-harness
        if (!assertions) throw new IllegalStateException("SelfTest requires -ea");
        if (args.length > 0) {
            if (args.length == 1 && args[0].equals("--inject-failure")) {
                assert false : "injected harness failure";
            }
            throw new IllegalArgumentException("unknown test argument");
        }
        ByteArrayOutputStream output = new ByteArrayOutputStream();
        try (PrintStream stream = new PrintStream(output, true, StandardCharsets.UTF_8)) {
            SelfCheck.run(stream);
        }
        assert output.toString(StandardCharsets.UTF_8).endsWith("[pass] java self-check OK\n");
        routesAndJson();
        PatternTest.run();
        valueBoundaries();
        snapshots();
        concurrentRequests();
        http();
        options();
        System.out.println("[pass] java SelfTest OK");
    }

    private static Api.Result request(Api api, String method, String path, String body) {
        return api.handle(new Api.Request(method, path, body));
    }

    private static void routesAndJson() {
        Api api = Api.create();
        assert request(api, "POST", "/items", Json.name("中文")).status() == 201;
        assert request(api, "POST", "/items", "{\"name\":\"Ada\\\\Q\\\"\"}").status() == 201;
        assert Json.parseName("{\"\\u006eame\":\"\\u0041da\"}").equals("Ada");
        assert Json.quote("\0\b\f\n\r\t\"\\").equals("\"\\u0000\\b\\f\\n\\r\\t\\\"\\\\\"");
        assert Json.quote("😀").equals("\"😀\"");
        String[] invalid = {
            "",
            "[]",
            "null",
            "{\"name\":1}",
            "{\"other\":\"Ada\"}",
            "{\"name\":\"Ada\",\"name\":\"Bob\"}",
            "{\"name\":\"Ada\",\"extra\":0}",
            "{\"name\":\"Ada\"} trailing",
            "{\"name\":\"Ada\",}",
            "{\"name\":\"Ada}",
            "{\"name\":\"\\q\"}",
            "{\"name\":\"\\u0x41\"}",
            "{\"name\":\"\\u１２３４\"}",
            "{\"name\":\"\\uD800\"}",
            "{\"name\":\"\\uDC00\"}",
            "{\"name\":\"a\nb\"}",
            "{\"name\":\"a\\nb\"}",
            Json.name("a".repeat(65)),
            Json.name("!bad")
        };
        for (String json : invalid) {
            assert request(api, "POST", "/items", json).status() == 400 : json;
        }
        assert api.snapshot().size() == 2;
        assert request(api, "POST", "/items", Json.name("Third")).body().startsWith("{\"id\":3,");
        for (String id :
                List.of("0", "-1", "01", "x", "", "2147483648", "99999999999", "1/extra")) {
            assert request(api, "GET", "/items/" + id, "").status() == 400;
        }
        assert request(api, "PUT", "/items/99", Json.name("Missing")).status() == 404;
        assert request(api, "DELETE", "/items/99", "").status() == 404;
        assert request(api, "PATCH", "/items/1", "").status() == 405;
        assert request(api, "PUT", "/items", "").status() == 405;
        assert request(api, "POST", "/healthz", "").status() == 405;
        assert request(api, "GET", "/unknown", "").status() == 404;
        ValidationException failure = expect(ValidationException.class, () -> Json.parseName("{}"));
        assert failure.getMessage().contains("expected");
        var cause = new NumberFormatException("bad id");
        assert new ValidationException("id out of range", cause).getCause() == cause;
    }

    private static void valueBoundaries() throws Exception {
        String input = new String("Ada");
        assert input != "Ada" && input.equals("Ada"); // L1-002-identity-equality
        assert input.intern() == "Ada" && input.concat(" Q").equals("Ada Q"); // L1-004-string-pool
        assert input.equals("Ada");
        Api.Item first = new Api.Item(1, input);
        Api.Item equal = new Api.Item(1, "Ada");
        HashSet<Api.Item> keys = new HashSet<>();
        keys.add(first);
        keys.add(equal);
        assert keys.size() == 1 && first.hashCode() == equal.hashCode(); // L1-003-equality-contract

        List<Api.Item> source = new ArrayList<>(List.of(first));
        List<Api.Item> alias = source;
        addAndRebind(source, equal);
        assert alias == source && source.size() == 2; // L1-001-reference-values
        List<Api.Item> view = Collections.unmodifiableList(source);
        List<Api.Item> copy = List.copyOf(source);
        source.clear();
        assert view.isEmpty() && copy.size() == 2;
        expect(UnsupportedOperationException.class, () -> copy.add(first));

        List<Object> destination = new ArrayList<>();
        transfer(copy, destination);
        assert destination.equals(copy);
        assert new ArrayList<Api.Item>().getClass()
                == new ArrayList<String>().getClass(); // L1-015-type-erasure
        assert Api.class
                .getMethod("snapshot")
                .getGenericReturnType()
                .getTypeName()
                .equals("java.util.List<devbox.rest.Api$Item>");

        Api api = Api.create();
        assert !api.ready();
        assert api.health().status() == 200;
        assert api.ready();
        var method = api.getClass().getDeclaredMethod("find", int.class);
        expect(IllegalAccessException.class, () -> method.invoke(api, 1));
        assert method.trySetAccessible(); // L1-028-reflection-access
        assert method.invoke(api, 1).equals(java.util.Optional.empty());
        expect(NoSuchMethodException.class, () -> api.getClass().getDeclaredMethod("missing"));

        assert Objects.equals(null, null) && !Objects.equals(null, first);
        expect(NullPointerException.class, () -> new Api.Request(null, "/", ""));
        expect(NullPointerException.class, () -> api.handle(null));
        expect(IllegalArgumentException.class, () -> new Api.Item(0, "Ada"));
        expect(ArithmeticException.class, () -> Math.addExact(Integer.MAX_VALUE, 1));
    }

    private static void addAndRebind(List<Api.Item> items, Api.Item item) {
        items.add(item);
        items = new ArrayList<>();
        assert items.isEmpty();
    }

    private static <T> void transfer(
            List<? extends T> source, List<? super T> target) { // L1-016-wildcard-pecs
        target.addAll(source);
    }

    private static void snapshots() throws Exception {
        Api api = Api.create();
        request(api, "POST", "/items", Json.name("中文"));
        List<Api.Item> before = api.snapshot();
        byte[] bytes = Snapshot.encode(before);
        assert bytes[0] == 1 && bytes[1] == 2 && bytes[2] == 3 && bytes[3] == 4;
        assert Snapshot.decode(bytes).equals(before);
        request(api, "DELETE", "/items/1", "");
        assert before.size() == 1 && api.snapshot().isEmpty();
        expect(IOException.class, () -> Snapshot.decode(new byte[0]));
        expect(
                IOException.class,
                () -> Snapshot.decode(java.util.Arrays.copyOf(bytes, bytes.length - 1)));
        byte[] corrupt = bytes.clone();
        corrupt[0] = 0;
        expect(IOException.class, () -> Snapshot.decode(corrupt));
        byte[] oversized = bytes.clone();
        oversized[16] = 127;
        expect(IOException.class, () -> Snapshot.decode(oversized));
        byte[] count = bytes.clone();
        count[8] = 127;
        expect(IOException.class, () -> Snapshot.decode(count));
        expect(
                IOException.class,
                () -> Snapshot.decode(java.util.Arrays.copyOf(bytes, bytes.length + 1)));
        expect(
                IOException.class,
                () -> Snapshot.encode(List.of(before.getFirst(), before.getFirst())));
    }

    private static void concurrentRequests() throws Exception {
        Api api = Api.create();
        AtomicReference<Throwable> workerFailure = new AtomicReference<>();
        Runnable task =
                () -> {
                    try {
                        for (int i = 0; i < 100; i++) {
                            assert request(api, "POST", "/items", Json.name("Worker")).status()
                                    == 201;
                        }
                    } catch (AssertionError | RuntimeException e) {
                        workerFailure.set(e);
                    }
                };
        Thread worker = new Thread(task, "rest-writer");
        worker.start(); // L1-029-thread-runnable
        task.run();
        worker.join(5000);
        if (worker.isAlive()) {
            worker.interrupt();
            throw new AssertionError("writer timeout");
        }
        if (workerFailure.get() != null)
            throw new AssertionError("worker failed", workerFailure.get());
        assert api.ready() && api.snapshot().size() == 200;
        assert request(api, "GET", "/metrics", "").body().equals("requests_total 201\n");
        assert api.snapshot().stream().map(Api.Item::id).distinct().count() == 200;

        try (var pool = Executors.newFixedThreadPool(4)) {
            List<CompletableFuture<Api.Result>> futures = new ArrayList<>();
            for (int i = 0; i < 4; i++) {
                final String name = "Async" + i;
                futures.add(
                        CompletableFuture.supplyAsync(
                                () -> request(api, "POST", "/items", Json.name(name)),
                                pool)); // L3-001-concurrent-pipeline
            }
            CompletableFuture.allOf(futures.toArray(CompletableFuture<?>[]::new))
                    .get(5, TimeUnit.SECONDS);
            assert futures.stream()
                    .map(CompletableFuture::join)
                    .allMatch(result -> result.status() == 201);
            Future<Integer> good = pool.submit(() -> api.snapshot().size());
            assert good.get(5, TimeUnit.SECONDS) == 204; // L1-032-executor-future
            Future<Integer> bad =
                    pool.submit(
                            () -> {
                                throw new ValidationException("task failed");
                            });
            assert expect(ExecutionException.class, () -> bad.get(5, TimeUnit.SECONDS)).getCause()
                    instanceof ValidationException;
            var failed =
                    CompletableFuture.supplyAsync(
                            () -> {
                                throw new ValidationException("async failed");
                            },
                            pool);
            assert expect(ExecutionException.class, () -> failed.get(5, TimeUnit.SECONDS))
                            .getCause()
                    instanceof ValidationException;
        }
        try (var virtual = Executors.newVirtualThreadPerTaskExecutor()) { // L3-002-virtual-threads
            List<Future<Boolean>> results = new ArrayList<>();
            for (int i = 0; i < 3; i++) {
                results.add(
                        virtual.submit(
                                () ->
                                        Thread.currentThread().isVirtual()
                                                && request(api, "GET", "/healthz", "").status()
                                                        == 200));
            }
            for (Future<Boolean> result : results) assert result.get(5, TimeUnit.SECONDS);
        }

        Api published = Api.create();
        CountDownLatch done = new CountDownLatch(1);
        AtomicReference<Throwable> readerFailure = new AtomicReference<>();
        Thread reader =
                new Thread(
                        () -> {
                            try {
                                long deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(5);
                                while (!published.ready()) {
                                    if (System.nanoTime() > deadline)
                                        throw new AssertionError("publication timeout");
                                    Thread.onSpinWait();
                                }
                                assert published.snapshot().getFirst().name().equals("Published");
                            } catch (AssertionError | RuntimeException e) {
                                readerFailure.set(e);
                            } finally {
                                done.countDown();
                            }
                        },
                        "rest-reader");
        reader.start();
        request(published, "POST", "/items", Json.name("Published"));
        assert done.await(6, TimeUnit.SECONDS);
        reader.join(1000);
        if (readerFailure.get() != null)
            throw new AssertionError("publication failed", readerFailure.get());

        AtomicInteger visited = new AtomicInteger();
        final int minimum = 202;
        var pipeline =
                api.snapshot().stream()
                        .filter(item -> item.id() >= minimum)
                        .peek(item -> visited.incrementAndGet())
                        .map(Api.Item::name); // L1-019-lambda-method-reference
        assert visited.get() == 0;
        assert pipeline.toList().size() == 3 && visited.get() == 3; // L1-020-stream-pipeline
        expect(IllegalStateException.class, pipeline::count);
    }

    private static void http() throws Exception {
        try (HttpApp app = HttpApp.start(Api.create(), 0);
                HttpClient client = HttpClient.newHttpClient()) {
            String base = "http://127.0.0.1:" + app.port();
            var create =
                    send(
                            client,
                            base,
                            "POST",
                            "/items",
                            Json.name("中文").getBytes(StandardCharsets.UTF_8),
                            "application/json");
            assert create.statusCode() == 201 && create.body().equals("{\"id\":1,\"name\":\"中文\"}");
            assert create.headers()
                    .firstValue("Content-Type")
                    .orElseThrow()
                    .contains("charset=utf-8");
            assert send(client, base, "GET", "/items/1", new byte[0], "application/json")
                            .statusCode()
                    == 200;
            assert send(
                                    client,
                                    base,
                                    "PUT",
                                    "/items/1",
                                    Json.name("Changed").getBytes(StandardCharsets.UTF_8),
                                    "application/json; charset=utf-8")
                            .statusCode()
                    == 200;
            assert send(client, base, "GET", "/healthz", new byte[0], "application/json")
                    .body()
                    .equals("{\"status\":\"ok\"}");
            assert send(client, base, "GET", "/items", new byte[0], "application/json")
                    .body()
                    .equals("[{\"id\":1,\"name\":\"Changed\"}]");
            assert send(
                                    client,
                                    base,
                                    "POST",
                                    "/items",
                                    new byte[] {(byte) 0xff},
                                    "application/json")
                            .statusCode()
                    == 400;
            assert send(client, base, "POST", "/items", new byte[4097], "application/json")
                            .statusCode()
                    == 400;
            assert send(client, base, "POST", "/items", new byte[0], "text/plain").statusCode()
                    == 415;
            assert send(client, base, "GET", "/items?q=1", new byte[0], "application/json")
                            .statusCode()
                    == 400;
            assert send(client, base, "DELETE", "/items/1", new byte[0], "application/json")
                    .body()
                    .isEmpty();
            assert send(client, base, "GET", "/items/1", new byte[0], "application/json")
                            .statusCode()
                    == 404;
            assert send(client, base, "GET", "/metrics", new byte[0], "application/json")
                    .body()
                    .equals("requests_total 8\n");
        }
    }

    private static HttpResponse<String> send(
            HttpClient client, String base, String method, String path, byte[] body, String type)
            throws Exception {
        return client.send(
                HttpRequest.newBuilder(URI.create(base + path))
                        .timeout(Duration.ofSeconds(5))
                        .header("Content-Type", type)
                        .method(method, HttpRequest.BodyPublishers.ofByteArray(body))
                        .build(),
                HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
    }

    private static void options() {
        assert Main.Options.parse(new String[] {"--self-check"}).selfCheck();
        assert Main.Options.parse(new String[] {"--port", "1234"}).port() == 1234;
        assert Main.Options.parse(new String[] {"--help"}).help();
        for (String[] args :
                List.of(
                        new String[] {"--bad"},
                        new String[] {"--port"},
                        new String[] {"--port", "x"},
                        new String[] {"--port", "0"},
                        new String[] {"--port", "65536"},
                        new String[] {"--seed"},
                        new String[] {"--self-check", "--port", "8080"})) {
            expect(IllegalArgumentException.class, () -> Main.Options.parse(args));
        }
    }

    @FunctionalInterface
    interface Throwing {
        void run() throws Exception;
    }

    static <E extends Exception> E expect(Class<E> type, Throwing action) {
        try {
            action.run();
        } catch (Exception e) {
            if (type.isInstance(e)) return type.cast(e);
            throw new AssertionError("expected " + type.getSimpleName() + ", got " + e, e);
        }
        throw new AssertionError("expected " + type.getSimpleName());
    }
}
