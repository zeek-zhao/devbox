package devbox.rest;

import java.io.PrintStream;

/** Fixed route sequence: never constructs or starts an HTTP adapter. */
public final class SelfCheck {
    private SelfCheck() {}

    /**
     * Verifies a deterministic CRUD sequence on the current JDK.
     * @param output destination
     * @throws AssertionError unexpected response
     */
    public static void run(PrintStream output) {
        if (Runtime.version().feature() < 21) throw new AssertionError("requires JDK 21"); // hello
        Api api = Api.create();
        check(api, output, "GET", "/healthz", "", 200, "{\"status\":\"ok\"}");
        check(api, output, "POST", "/items", "{\"name\":\"Ada \\\"Q\\\"\"}", 201,
                "{\"id\":1,\"name\":\"Ada \\\"Q\\\"\"}");
        check(api, output, "GET", "/items/1", "", 200, "{\"id\":1,\"name\":\"Ada \\\"Q\\\"\"}");
        check(api, output, "PUT", "/items/1", "{\"name\":\"Grace\"}", 200, "{\"id\":1,\"name\":\"Grace\"}");
        check(api, output, "POST", "/items", "{\"name\":\"\"}", 400,
                "{\"error\":\"name must be 1..64 letters, digits or safe punctuation\"}");
        check(api, output, "GET", "/items", "", 200, "[{\"id\":1,\"name\":\"Grace\"}]");
        check(api, output, "DELETE", "/items/1", "", 204, "");
        check(api, output, "GET", "/items/1", "", 404, "{\"error\":\"item not found\"}");
        check(api, output, "GET", "/missing", "", 404, "{\"error\":\"route not found\"}");
        check(api, output, "GET", "/metrics", "", 200, "requests_total 10\n");
        output.println("[pass] java self-check OK");
    }

    private static void check(Api api, PrintStream out, String method, String path, String body,
                              int status, String expected) {
        Api.Result result = api.handle(new Api.Request(method, path, body));
        if (result.status() != status || !result.body().equals(expected)) {
            throw new AssertionError(method + " " + path + ": " + result);
        }
        out.println((method + " " + path + " -> " + status + " " + result.body()).stripTrailing());
    }
}
