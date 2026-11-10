import java.util.HashMap;
import java.util.Map;

public class Main {
    abstract static class DomainError extends RuntimeException {
        DomainError(String message) {
            super(message);
        }
    }

    static final class ValidationError extends DomainError {
        ValidationError(String field, Object value) {
            super("field " + field + " invalid value " + value);
        }
    }

    static final class TransientError extends DomainError {
        TransientError(String op, int attempt) {
            super("op " + op + " failed at attempt " + attempt);
        }
    }

    static final class BugError extends DomainError {
        BugError(String component) {
            super("internal bug in " + component);
        }
    }

    static String classify(DomainError err) {
        if (err instanceof ValidationError) {
            return "VALIDATION";
        }
        if (err instanceof TransientError) {
            return "TRANSIENT";
        }
        return "INTERNAL";
    }

    static String actionFor(String category) {
        if ("VALIDATION".equals(category)) {
            return "reject-input";
        }
        if ("TRANSIENT".equals(category)) {
            return "retry";
        }
        return "fail-fast";
    }

    public static void main(String[] args) {
        DomainError[] errs = {
            new ValidationError("age", -1),
            new TransientError("fetch-user", 2),
            new BugError("kv-store"),
        };
        Map<String, Integer> counts = new HashMap<>();
        for (DomainError err : errs) {
            String category = classify(err);
            counts.merge(category, 1, Integer::sum);
            System.out.println(
                    err.getMessage()
                            + " -> category="
                            + category
                            + " action="
                            + actionFor(category));
        }
        System.out.println(
                "taxonomy types="
                        + errs.length
                        + " VALIDATION="
                        + counts.getOrDefault("VALIDATION", 0)
                        + " TRANSIENT="
                        + counts.getOrDefault("TRANSIENT", 0)
                        + " INTERNAL="
                        + counts.getOrDefault("INTERNAL", 0));
    }
}
