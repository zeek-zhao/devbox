import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

public class Main {
    static final class ValidationException extends RuntimeException {
        ValidationException(String message) {
            super(message);
        }
    }

    static final class TransientException extends RuntimeException {
        TransientException(String message) {
            super(message);
        }
    }

    static String convert(String doc) {
        switch (doc) {
            case "doc-2":
                throw new ValidationException("schema mismatch");
            case "doc-4":
                throw new TransientException("storage busy");
            default:
                return "ok";
        }
    }

    public static void main(String[] args) throws Exception {
        List<Callable<String>> tasks = new ArrayList<>();
        for (String doc : new String[] {"doc-1", "doc-2", "doc-3", "doc-4"}) {
            tasks.add(() -> convert(doc));
        }
        ExecutorService pool = Executors.newFixedThreadPool(2);
        List<Future<String>> futures = pool.invokeAll(tasks);
        int ok = 0;
        int failed = 0;
        for (int i = 0; i < futures.size(); i++) {
            String doc = "doc-" + (i + 1);
            try {
                futures.get(i).get();
                System.out.println(doc + ": ok");
                ok++;
            } catch (ExecutionException err) {
                System.out.println(
                        doc
                                + ": FAILED "
                                + err.getCause().getClass().getSimpleName()
                                + " ("
                                + err.getCause().getMessage()
                                + ")");
                failed++;
            }
        }
        pool.shutdown();
        System.out.println(
                "aggregate: ok="
                        + ok
                        + " failed="
                        + failed
                        + " -> collect all failures before deciding");
        System.out.println("rule: per-task failures are recorded, then reported once");
    }
}
