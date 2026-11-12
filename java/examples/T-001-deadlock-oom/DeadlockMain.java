/** T-001-deadlock-oom 被测程序一：两把锁反序死锁（素材 S-14）。 */
import java.util.concurrent.CountDownLatch;

public final class DeadlockMain {

    private static final Object LOCK_A = new Object();
    private static final Object LOCK_B = new Object();
    private static final CountDownLatch GATE = new CountDownLatch(2);

    private DeadlockMain() {}

    public static void main(String[] args) throws InterruptedException {
        System.out.println("deadlock: start");
        Thread t1 = new Thread(() -> lockOrder(LOCK_A, LOCK_B), "worker-1");
        Thread t2 = new Thread(() -> lockOrder(LOCK_B, LOCK_A), "worker-2");
        t1.start();
        t2.start();
        t1.join(); // 两把锁互等，join 永远等不到 —— 程序活着但卡死
        t2.join();
        System.out.println("deadlock: done");
    }

    private static void lockOrder(Object first, Object second) {
        synchronized (first) {
            GATE.countDown(); // 我已拿到第一把锁
            awaitGate(); // 等对方也拿到第一把锁，两线程同时去抢第二把 → 死锁必现
            synchronized (second) {
                System.out.println("critical: entered by " + Thread.currentThread().getName());
            }
        }
    }

    private static void awaitGate() {
        try {
            GATE.await();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
