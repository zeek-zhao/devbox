import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;

public final class Main {
    private int payload;
    private volatile boolean ready;
    private volatile int counter;

    private void increment() {
        counter++;
    }

    public static void main(String[] args) throws InterruptedException {
        Main publication = new Main();
        CountDownLatch started = new CountDownLatch(1);
        AtomicReference<Integer> observed = new AtomicReference<>();
        AtomicReference<Throwable> failure = new AtomicReference<>();
        Thread reader = new Thread(() -> {
            started.countDown();
            long deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(2);
            while (!publication.ready) {
                if (System.nanoTime() >= deadline) {
                    failure.set(new IllegalStateException("publication timed out"));
                    return;
                }
                Thread.onSpinWait();
            }
            observed.set(publication.payload);
        });

        reader.start();
        if (!started.await(2, TimeUnit.SECONDS)) {
            throw new IllegalStateException("reader start timed out");
        }
        publication.payload = 42;
        publication.ready = true;
        reader.join(2_000);
        if (reader.isAlive()) {
            throw new IllegalStateException("reader join timed out");
        }
        if (failure.get() != null) {
            throw new IllegalStateException("reader failed", failure.get());
        }
        if (!Integer.valueOf(42).equals(observed.get())) {
            throw new IllegalStateException("published payload mismatch");
        }
        System.out.println("published-payload=" + observed.get());
    }
}
