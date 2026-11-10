import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

public class Main {
    public static void main(String[] args) throws InterruptedException {
        Thread worker =
                new Thread(
                        () -> {
                            throw new IllegalStateException("worker-1 exploded");
                        },
                        "worker-1");
        worker.setUncaughtExceptionHandler(
                (thread, err) ->
                        System.out.println(
                                "handler: caught "
                                        + err.getClass().getSimpleName()
                                        + " from "
                                        + thread.getName()));
        worker.start();
        worker.join();

        ExecutorService pool = Executors.newSingleThreadExecutor();
        Future<String> silent =
                pool.submit(
                        () -> {
                            throw new IllegalStateException("task exploded");
                        });
        System.out.println("executor-no-get: future held the failure, nothing surfaced");
        try {
            silent.get();
        } catch (ExecutionException err) {
            System.out.println(
                    "executor-get: "
                            + err.getClass().getSimpleName()
                            + " caused by "
                            + err.getCause().getClass().getSimpleName());
        }
        pool.shutdown();
        System.out.println("rule: every thread gets a handler or every future is observed");
    }
}
