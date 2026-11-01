import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

public final class Main {
    public static void main(String[] args) throws InterruptedException {
        ExecutorService executor = Executors.newFixedThreadPool(2);
        try {
            List<Future<Integer>> results =
                    List.of(executor.submit(() -> 2), executor.submit(() -> 4));
            List<Integer> values = new ArrayList<>();
            for (Future<Integer> result : results) {
                values.add(result.get(2, TimeUnit.SECONDS));
            }
            System.out.println("results=" + values);

            Future<Integer> failed =
                    executor.submit(
                            () -> {
                                throw new IllegalArgumentException("fixed failure");
                            });
            try {
                failed.get(2, TimeUnit.SECONDS);
                throw new IllegalStateException("task failure was not reported");
            } catch (ExecutionException exception) {
                if (!(exception.getCause() instanceof IllegalArgumentException)
                        || !"fixed failure".equals(exception.getCause().getMessage())) {
                    throw new IllegalStateException("unexpected task failure", exception);
                }
                System.out.println("task-failure=IllegalArgumentException");
            }
        } catch (ExecutionException | java.util.concurrent.TimeoutException exception) {
            throw new IllegalStateException("task did not complete successfully", exception);
        } finally {
            executor.shutdown();
            if (!executor.awaitTermination(2, TimeUnit.SECONDS)) {
                executor.shutdownNow();
                if (!executor.awaitTermination(2, TimeUnit.SECONDS)) {
                    throw new IllegalStateException("executor termination timed out");
                }
            }
        }
        System.out.println("executor-terminated=true");
    }
}
