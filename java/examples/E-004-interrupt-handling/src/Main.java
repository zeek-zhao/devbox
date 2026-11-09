public class Main {
    public static void main(String[] args) throws InterruptedException {
        Thread worker =
                new Thread(
                        () -> {
                            try {
                                Thread.sleep(5000);
                                System.out.println("worker: finished sleep (unexpected)");
                            } catch (InterruptedException err) {
                                System.out.println("worker: interrupted during sleep");
                                Thread.currentThread().interrupt();
                                System.out.println(
                                        "worker: flag restored="
                                                + Thread.currentThread().isInterrupted());
                            }
                            if (Thread.currentThread().isInterrupted()) {
                                System.out.println("worker: stopped cooperatively");
                            }
                        },
                        "worker-1");
        worker.start();
        Thread.sleep(50);
        worker.interrupt();
        worker.join();
        System.out.println("main: worker finished, not killed");
        System.out.println("rule: catching InterruptedException must restore the flag or exit");
    }
}
