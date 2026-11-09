import java.util.ArrayList;
import java.util.List;

public class Main {
    static final class StorageException extends RuntimeException {
        StorageException(String message) {
            super(message);
        }
    }

    record Source(String name, Loader loader) {
        interface Loader {
            String load();
        }
    }

    static Source primary() {
        return new Source(
                "primary-db",
                () -> {
                    throw new StorageException("TRANSIENT primary-db offline");
                });
    }

    static Source cache() {
        return new Source("cache", () -> "stale-snapshot");
    }

    static Source archive() {
        return new Source(
                "archive",
                () -> {
                    throw new StorageException("PERMANENT archive unreadable");
                });
    }

    static String load(List<Source> sources, List<String> failures, String[] servedBy) {
        for (Source source : sources) {
            try {
                String result = source.loader().load();
                servedBy[0] = source.name();
                return result;
            } catch (StorageException err) {
                failures.add(source.name() + ": " + err.getMessage());
            }
        }
        throw new IllegalStateException("no source available: " + String.join("; ", failures));
    }

    public static void main(String[] args) {
        List<String> failures = new ArrayList<>();
        String[] servedBy = new String[1];
        String result = load(List.of(primary(), cache()), failures, servedBy);
        System.out.println("primary failed: " + failures.get(0));
        System.out.println("fallback: " + result + " (served by " + servedBy[0] + ")");
        System.out.println("degradation: failed-sources=" + failures.size());

        try {
            load(List.of(primary(), archive()), new ArrayList<>(), servedBy);
        } catch (IllegalStateException err) {
            System.out.println("no-source: " + err.getMessage());
        }
        System.out.println(
                "rule: degrade with recorded reasons; fail only when every path is down");
    }
}
