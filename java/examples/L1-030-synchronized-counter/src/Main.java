public class Main {
    private static final class Counter {
        private final Object lock = new Object();
        private int value;

        private void increment() {
            synchronized (lock) {
                value++;
            }
        }

        private int value() {
            synchronized (lock) {
                return value;
            }
        }
    }

    public static void main(String[] args) throws InterruptedException {
        Counter counter = new Counter();
        Runnable increments =
                () -> {
                    for (int index = 0; index < 1000; index++) {
                        counter.increment();
                    }
                };
        Thread first = new Thread(increments);
        Thread second = new Thread(increments);
        first.start();
        second.start();
        first.join();
        second.join();
        System.out.println("count=" + counter.value());
        System.out.println("shared-lock=true");
    }
}
