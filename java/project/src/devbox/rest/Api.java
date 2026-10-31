package devbox.rest;

import java.util.List;
import java.util.Objects;

/** Public business boundary, independent of HTTP transport and console output. */
public interface Api { // L2-009-module-layers
    /**
     * Routes one request and atomically updates the in-memory store.
     * @param request non-null request with non-null components
     * @return an immutable status, content type and body
     * @throws NullPointerException if request is null
     */
    Result handle(Request request); // L2-004-api-javadoc

    /**
     * Copies the current items.
     * @return a sorted immutable snapshot of the items
     */
    List<Item> snapshot();

    /**
     * Creates an independent store.
     * @return a new isolated service
     */
    static Api create() { return new RestService(); }

    /**
     * Checks publication of service state.
     * @return true once a request has completed
     */
    boolean ready();

    /**
     * Runs a health request without transport.
     * @return the health response
     */
    default Result health() { return handle(new Request("GET", "/healthz", "")); } // L1-010-interface-methods

    /**
     * Input envelope.
     * @param method HTTP method
     * @param path raw URL path
     * @param body UTF-8 decoded body
     */
    record Request(String method, String path, String body) {
        /** Rejects nulls at the boundary.
         * @param method HTTP method
         * @param path raw URL path
         * @param body UTF-8 decoded body
         */
        public Request {
            Objects.requireNonNull(method, "method"); // L1-033-null-boundaries
            Objects.requireNonNull(path, "path");
            Objects.requireNonNull(body, "body");
        }
    }

    /**
     * Stored immutable value.
     * @param id positive identifier
     * @param name validated name
     */
    record Item(int id, String name) { // L1-026-record-model
        /**
         * Validates the item.
         * @param id positive identifier
         * @param name validated name
         */
        public Item {
            if (id < 1) throw new IllegalArgumentException("id must be positive");
            name = Json.validateName(name);
        }
    }

    /**
     * Wire result.
     * @param status HTTP code
     * @param contentType media type
     * @param body response
     */
    record Result(int status, String contentType, String body) {}
}
