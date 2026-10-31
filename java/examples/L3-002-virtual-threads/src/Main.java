import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

public class Main {
    public static void main(String[] args) throws Exception {
        int[] values = {1, 2, 3};
        List<Integer> results = new ArrayList<>();
        boolean allVirtual = true;
        String failureCause = "";
        try (ExecutorService executor = Executors.newVirtualThreadPerTaskExecutor()) {
            List<Future<TaskResult>> futures = new ArrayList<>();
            for (int value : values) {
                futures.add(executor.submit(() ->
                        new TaskResult(value * value, Thread.currentThread().isVirtual())));
            }
            for (Future<TaskResult> future : futures) {
                TaskResult result = future.get(5, TimeUnit.SECONDS);
                results.add(result.value());
                allVirtual &= result.virtual();
            }
            Future<Integer> failed = executor.submit(() -> {
                throw new IllegalArgumentException("fixed failure");
            });
            try {
                failed.get(5, TimeUnit.SECONDS);
                throw new IllegalStateException("failed virtual task was accepted");
            } catch (ExecutionException expected) {
                if (!(expected.getCause() instanceof IllegalArgumentException)) {
                    throw expected;
                }
                failureCause = expected.getCause().getClass().getSimpleName();
            }
        }
        if (!allVirtual || results.size() != values.length) {
            throw new IllegalStateException("virtual task result validation failed");
        }
        System.out.println("results: " + results);
        System.out.println("all-virtual: " + allVirtual);
        System.out.println("completed: " + results.size());
        System.out.println("failure-cause: " + failureCause);
    }

    private record TaskResult(int value, boolean virtual) {
    }
}
