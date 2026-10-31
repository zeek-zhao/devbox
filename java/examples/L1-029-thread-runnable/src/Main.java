import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;
import java.util.concurrent.atomic.AtomicBoolean;

public class Main {
    public static void main(String[] args) throws InterruptedException {
        Thread caller = Thread.currentThread();
        AtomicInteger completed = new AtomicInteger();
        AtomicReference<Throwable> workerFailure = new AtomicReference<>();
        AtomicBoolean workerOnNewThread = new AtomicBoolean();
        Runnable task = () -> {
            try {
                workerOnNewThread.set(Thread.currentThread() != caller);
                completed.incrementAndGet();
            } catch (RuntimeException | Error failure) {
                workerFailure.compareAndSet(null, failure);
            }
        };

        Thread worker = new Thread(task);
        worker.start();
        worker.join();
        System.out.println("start-is-new-thread=" + workerOnNewThread.get());

        task.run();
        System.out.println("direct-run-is-caller="
                + (Thread.currentThread() == caller));
        System.out.println("completed=" + completed.get());
        Throwable failure = workerFailure.get();
        System.out.println("worker-failure="
                + (failure == null ? "none" : failure.getClass().getSimpleName()));
    }
}
