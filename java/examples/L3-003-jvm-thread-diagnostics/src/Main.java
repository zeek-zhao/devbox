import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

public class Main {
    public static void main(String[] args) throws Exception {
        if (args.length > 0 && args[0].equals("worker")) {
            runWorker();
            return;
        }
        diagnoseWorker();
    }

    private static void runWorker() throws InterruptedException {
        CountDownLatch release = new CountDownLatch(1);
        Thread worker = new Thread(() -> parkHere(release), "diagnostic-worker");
        worker.start();
        long deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(5);
        while (worker.getState() != Thread.State.WAITING && System.nanoTime() < deadline) {
            Thread.onSpinWait();
        }
        if (worker.getState() != Thread.State.WAITING) {
            throw new IllegalStateException("worker did not enter wait");
        }
        System.out.println("READY");
        System.out.flush();
        try (BufferedReader input = new BufferedReader(
                new InputStreamReader(System.in, StandardCharsets.UTF_8))) {
            input.readLine();
        } catch (IOException exception) {
            throw new IllegalStateException("worker handshake failed", exception);
        } finally {
            release.countDown();
        }
        worker.join(5000);
        if (worker.isAlive()) {
            throw new IllegalStateException("worker did not stop");
        }
    }

    private static void parkHere(CountDownLatch release) {
        try {
            release.await();
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
        }
    }

    private static void diagnoseWorker() throws Exception {
        String java = Path.of(System.getProperty("java.home"), "bin", "java").toString();
        Process child = new ProcessBuilder(java, "-cp", System.getProperty("java.class.path"),
                Main.class.getName(), "worker").start();
        String lastDump = "";
        try {
            BufferedReader childOutput = new BufferedReader(
                    new InputStreamReader(child.getInputStream(), StandardCharsets.UTF_8));
            long deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(5);
            while (!childOutput.ready() && child.isAlive() && System.nanoTime() < deadline) {
                Thread.onSpinWait();
            }
            if (!childOutput.ready() || !"READY".equals(childOutput.readLine())) {
                throw new IllegalStateException("worker readiness handshake failed");
            }

            String jcmd = Path.of(System.getProperty("java.home"), "bin", "jcmd").toString();
            boolean waiting = false;
            boolean frameFound = false;
            for (int attempt = 0; attempt < 5 && !frameFound; attempt++) {
                Process diagnostic = new ProcessBuilder(jcmd,
                        Long.toString(child.pid()), "Thread.print").start();
                if (!diagnostic.waitFor(3, TimeUnit.SECONDS)) {
                    diagnostic.destroyForcibly();
                    throw new IllegalStateException("jcmd Thread.print timed out");
                }
                lastDump = new String(diagnostic.getInputStream().readAllBytes(),
                        StandardCharsets.UTF_8);
                String workerFrames = workerFrames(lastDump);
                waiting = workerFrames.contains("WAITING");
                frameFound = workerFrames.contains("parkHere");
            }
            if (!waiting || !frameFound) {
                System.err.println(lastDump);
                throw new IllegalStateException("worker wait frame not found");
            }

            try (BufferedWriter childInput = new BufferedWriter(
                    new OutputStreamWriter(child.getOutputStream(), StandardCharsets.UTF_8))) {
                childInput.write("release");
                childInput.newLine();
            }
            if (!child.waitFor(5, TimeUnit.SECONDS) || child.exitValue() != 0) {
                throw new IllegalStateException("diagnostic worker did not exit cleanly");
            }
            System.out.println("worker-waiting: true");
            System.out.println("frame-found: true");
        } finally {
            if (child.isAlive()) {
                child.destroyForcibly();
                child.waitFor(5, TimeUnit.SECONDS);
            }
        }
    }

    private static String workerFrames(String dump) {
        StringBuilder frames = new StringBuilder();
        boolean inWorker = false;
        for (String line : dump.lines().toList()) {
            if (line.startsWith("\"")) {
                if (inWorker) {
                    break;
                }
                inWorker = line.contains("\"diagnostic-worker\"");
            }
            if (inWorker) {
                frames.append(line).append('\n');
            }
        }
        return frames.toString();
    }
}
