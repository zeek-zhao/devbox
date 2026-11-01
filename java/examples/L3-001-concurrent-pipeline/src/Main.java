import java.util.Map;
import java.util.TreeMap;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

public class Main {
    public static void main(String[] args) throws Exception {
        ExecutorService pool = Executors.newFixedThreadPool(4);
        try {
            ConcurrentHashMap<String, Integer> counts = new ConcurrentHashMap<>();
            AtomicInteger completed = new AtomicInteger();
            String[] words = {"a", "b", "a", "b"};
            CompletableFuture<?>[] tasks = new CompletableFuture<?>[words.length];
            for (int index = 0; index < words.length; index++) {
                String word = words[index];
                tasks[index] =
                        CompletableFuture.supplyAsync(() -> word, pool)
                                .thenApply(
                                        value -> {
                                            counts.merge(value, 1, Integer::sum);
                                            completed.incrementAndGet();
                                            return value;
                                        });
            }
            CompletableFuture.allOf(tasks).get(5, TimeUnit.SECONDS);
            Map<String, Integer> sorted = new TreeMap<>(counts);
            System.out.println("counts: " + sorted);
            System.out.println("completed: " + completed.get());

            CompletableFuture<Void> failed =
                    CompletableFuture.supplyAsync(
                                    () -> {
                                        throw new IllegalArgumentException("fixed failure");
                                    },
                                    pool)
                            .thenAccept(
                                    value -> {
                                        throw new IllegalStateException("unreachable");
                                    });
            try {
                failed.get(5, TimeUnit.SECONDS);
                throw new IllegalStateException("failed future was accepted");
            } catch (ExecutionException expected) {
                if (!(expected.getCause() instanceof IllegalArgumentException)) {
                    throw expected;
                }
                System.out.println(
                        "failure-cause: " + expected.getCause().getClass().getSimpleName());
            }
        } finally {
            pool.shutdown();
            if (!pool.awaitTermination(5, TimeUnit.SECONDS)) {
                pool.shutdownNow();
                throw new IllegalStateException("executor did not terminate");
            }
        }
    }
}
