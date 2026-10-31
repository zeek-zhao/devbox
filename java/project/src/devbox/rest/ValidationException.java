package devbox.rest;

/** A client input error, optionally retaining its original parsing failure. */
public final class ValidationException extends IllegalArgumentException { // L1-023-custom-exceptions
    private static final long serialVersionUID = 1L;

    /**
     * Creates an input failure.
     * @param message domain context
     */
    public ValidationException(String message) { super(message); }

    /**
     * Wraps a parsing failure.
     * @param message domain context
     * @param cause underlying parse failure
     */
    public ValidationException(String message, Throwable cause) { super(message, cause); }
}
