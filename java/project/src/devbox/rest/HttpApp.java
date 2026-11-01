package devbox.rest;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.logging.ConsoleHandler;
import java.util.logging.Formatter;
import java.util.logging.Level;
import java.util.logging.LogRecord;
import java.util.logging.Logger;

/** HTTP adapter with bounded request bodies and owned worker lifecycle. */
public final class HttpApp implements AutoCloseable {
    private static final int MAX_BODY = 4096;
    private static final Logger LOG = Logger.getLogger(HttpApp.class.getName());

    static {
        LOG.setUseParentHandlers(false);
        ConsoleHandler handler = new ConsoleHandler();
        handler.setFormatter(
                new Formatter() {
                    @Override
                    public String format(LogRecord record) {
                        String message = record.getLevel() + ":" + record.getMessage() + "\n";
                        if (record.getThrown() == null) return message;
                        java.io.StringWriter stack = new java.io.StringWriter();
                        record.getThrown().printStackTrace(new java.io.PrintWriter(stack));
                        return message + stack;
                    }
                });
        LOG.addHandler(handler); // L2-006-standard-logging
    }

    private final HttpServer server;
    private final ExecutorService workers;

    private HttpApp(HttpServer server, ExecutorService workers) {
        this.server = server;
        this.workers = workers;
    }

    /**
     * Starts the owned listener and workers.
     *
     * @param api service
     * @param port TCP port (0 chooses an ephemeral port for tests)
     * @return running adapter
     * @throws IOException listener creation failed
     */
    public static HttpApp start(Api api, int port) throws IOException {
        HttpServer server = HttpServer.create(new InetSocketAddress("127.0.0.1", port), 0);
        ExecutorService workers = Executors.newFixedThreadPool(4);
        HttpApp app = new HttpApp(server, workers);
        try {
            server.createContext("/", exchange -> app.respond(api, exchange));
            server.setExecutor(workers);
            server.start();
            return app;
        } catch (RuntimeException e) {
            app.close();
            throw e;
        }
    }

    /**
     * Reads the bound address.
     *
     * @return bound TCP port
     */
    public int port() {
        return server.getAddress().getPort();
    }

    private void respond(Api api, HttpExchange exchange) throws IOException {
        try {
            Api.Result result;
            try {
                String body;
                try (var input = exchange.getRequestBody()) { // L1-024-resource-closing
                    byte[] bytes = input.readNBytes(MAX_BODY + 1);
                    if (bytes.length > MAX_BODY) {
                        throw new ValidationException("body exceeds 4096 bytes");
                    }
                    body = decode(bytes);
                }
                String contentType = exchange.getRequestHeaders().getFirst("Content-Type");
                String method = exchange.getRequestMethod();
                if ((method.equals("POST") || method.equals("PUT"))
                        && (contentType == null
                                || !contentType
                                        .split(";", 2)[0]
                                        .strip()
                                        .equalsIgnoreCase("application/json"))) {
                    result =
                            new Api.Result(
                                    415,
                                    "application/json; charset=utf-8",
                                    "{\"error\":\"expected application/json\"}");
                } else if (exchange.getRequestURI().getRawQuery() != null) {
                    throw new ValidationException("query parameters not supported");
                } else {
                    result =
                            api.handle(
                                    new Api.Request(
                                            method, exchange.getRequestURI().getRawPath(), body));
                }
            } catch (ValidationException | CharacterCodingException e) {
                result =
                        new Api.Result(
                                400,
                                "application/json; charset=utf-8",
                                "{\"error\":"
                                        + Json.quote(
                                                e instanceof CharacterCodingException
                                                        ? "invalid UTF-8"
                                                        : e.getMessage())
                                        + "}");
            } catch (RuntimeException e) {
                LOG.log(Level.SEVERE, "handler failed", e);
                result =
                        new Api.Result(
                                500,
                                "application/json; charset=utf-8",
                                "{\"error\":\"internal error\"}");
            }
            byte[] bytes = result.body().getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().set("Content-Type", result.contentType());
            exchange.sendResponseHeaders(
                    result.status(), result.status() == 204 ? -1 : bytes.length);
            try (var output = exchange.getResponseBody()) {
                output.write(bytes);
            }
        } catch (IOException e) {
            LOG.log(Level.WARNING, "transport failed", e);
            throw e;
        } finally {
            exchange.close();
        }
    }

    private static String decode(byte[] bytes) throws CharacterCodingException {
        return StandardCharsets.UTF_8
                .newDecoder()
                .onMalformedInput(CodingErrorAction.REPORT)
                .onUnmappableCharacter(CodingErrorAction.REPORT)
                .decode(ByteBuffer.wrap(bytes))
                .toString();
    }

    /** Stops the listener and waits for owned worker threads. */
    @Override
    public void close() {
        server.stop(0);
        workers.shutdownNow();
        try {
            if (!workers.awaitTermination(5, java.util.concurrent.TimeUnit.SECONDS)) {
                throw new IllegalStateException("HTTP workers did not stop");
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("interrupted while closing HTTP workers", e);
        }
    }
}
