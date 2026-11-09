import java.lang.management.ManagementFactory;
import java.lang.management.ThreadMXBean;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class Main {
    static String[] detectDeadlockedNames() {
        ThreadMXBean mxBean = ManagementFactory.getThreadMXBean();
        long[] ids = mxBean.findDeadlockedThreads();
        if (ids == null) {
            return new String[0];
        }
        List<String> names = new ArrayList<>();
        for (long id : ids) {
            names.add(mxBean.getThreadInfo(id).getThreadName());
        }
        Collections.sort(names);
        return names.toArray(new String[0]);
    }

    static Thread crossWorker(String name, Object first, Object second) {
        Thread worker =
                new Thread(
                        () -> {
                            synchronized (first) {
                                try {
                                    Thread.sleep(100);
                                } catch (InterruptedException err) {
                                    Thread.currentThread().interrupt();
                                }
                                synchronized (second) {
                                    System.out.println(name + ": crossed");
                                }
                            }
                        },
                        name);
        worker.setDaemon(true);
        worker.start();
        return worker;
    }

    static Thread orderedWorker(String name, Object first, Object second) {
        Thread worker =
                new Thread(
                        () -> {
                            synchronized (first) {
                                synchronized (second) {
                                    System.out.println(name + ": crossed");
                                }
                            }
                        },
                        name);
        worker.setDaemon(true);
        worker.start();
        return worker;
    }

    public static void main(String[] args) throws InterruptedException {
        Object lockA = new Object();
        Object lockB = new Object();
        crossWorker("worker-1", lockA, lockB);
        crossWorker("worker-2", lockB, lockA);

        String[] deadlocked = new String[0];
        for (int i = 0; i < 50; i++) {
            Thread.sleep(50);
            deadlocked = detectDeadlockedNames();
            if (deadlocked.length > 0) {
                break;
            }
        }
        System.out.println("deadlock-detected: " + (deadlocked.length > 0));
        System.out.println("deadlocked-threads: " + String.join(",", deadlocked));

        Object fixA = new Object();
        Object fixB = new Object();
        Thread fix1 = orderedWorker("fix-1", fixA, fixB);
        Thread fix2 = orderedWorker("fix-2", fixA, fixB);
        fix1.join(2000);
        fix2.join(2000);
        System.out.println("fix-run: completed without deadlock (uniform lock order)");
        System.out.println(
                "rule: uniform lock order kills cycles; tryLock with timeout is the fallback");
    }
}
