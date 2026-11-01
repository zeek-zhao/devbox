package devbox.rest;

import java.util.Objects;

// L4-004-builder: require a complete wire envelope before exposing an immutable result.
final class ResultBuilder {
    private int status;
    private String contentType;
    private String body;

    ResultBuilder status(int status) {
        if (status < 100 || status > 599) {
            throw new IllegalArgumentException("status must be 100..599");
        }
        this.status = status;
        return this;
    }

    ResultBuilder contentType(String contentType) {
        Objects.requireNonNull(contentType, "contentType");
        if (contentType.isBlank()
                || contentType.indexOf('\r') >= 0
                || contentType.indexOf('\n') >= 0) {
            throw new IllegalArgumentException("invalid content type");
        }
        this.contentType = contentType;
        return this;
    }

    ResultBuilder body(String body) {
        this.body = Objects.requireNonNull(body, "body");
        return this;
    }

    Api.Result build() {
        if (status == 0 || contentType == null || body == null) {
            throw new IllegalStateException("incomplete result");
        }
        if (status == 204 && !body.isEmpty()) {
            throw new IllegalStateException("204 requires an empty body");
        }
        return new Api.Result(status, contentType, body);
    }
}
