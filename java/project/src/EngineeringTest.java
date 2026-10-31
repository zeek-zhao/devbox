import devbox.rest.Api;
import devbox.rest.Json;
import devbox.rest.Snapshot;
import devbox.tests.NativeChecksum;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

/** Build-time probes requiring a full development JDK, never used by self-check. */
public final class EngineeringTest {
    private EngineeringTest() {}

    public static void main(String[] args) throws Exception {
        if (!EngineeringTest.class.desiredAssertionStatus()) throw new IllegalStateException("requires -ea");
        Api api = Api.create();
        for (int i = 0; i < 1000; i++) {
            assert api.handle(new Api.Request("POST", "/items", Json.name("Item" + i))).status() == 201;
        }
        List<Api.Item> items = Snapshot.decode(Snapshot.encode(api.snapshot()));
        countedLookup(items);
        int[] ids = items.stream().mapToInt(Api.Item::id).toArray();
        assert NativeChecksum.sum(ids) == 500500;
        SelfTest.expect(NullPointerException.class, () -> NativeChecksum.sum(null));
        missingNative();
        diagnostics();
        seedFile();
        System.out.println("[pass] java engineering OK");
    }

    private static void countedLookup(List<Api.Item> items) {
        Lookup linear = new Linear();
        Lookup binary = new Binary();
        for (int i = 0; i < 100; i++) {
            assert linear.find(items, 1000).item().equals(binary.find(items, 1000).item());
        }
        long start = System.nanoTime();
        long checksum = 0;
        for (int i = 0; i < 1000; i++) {
            Found a = linear.find(items, 1000);
            Found b = binary.find(items, 1000);
            assert a.visits() == 1000 && b.visits() <= 10; // L3-005-counted-benchmark
            checksum += a.item().id() + b.item().id();
        }
        assert checksum == 2000000 && System.nanoTime() >= start;
        assert linear.find(items, 1001).item() == null && binary.find(items, 1001).item() == null;
        Object boxed = Integer.valueOf(1000);
        assert binary.describe(boxed).equals("object");
        assert binary.describe(1000).equals("id");
        assert binary.label().equals("binary"); // L1-009-dispatch-overloads
    }

    private record Found(Api.Item item, int visits) {}
    private abstract static class Lookup {
        abstract Found find(List<Api.Item> items, int id);
        String label() { return "lookup"; }
        String describe(Object id) { return "object"; }
        String describe(int id) { return "id"; }
    }
    private static final class Linear extends Lookup {
        @Override Found find(List<Api.Item> items, int id) {
            int visits = 0;
            for (Api.Item item : items) {
                visits++;
                if (item.id() == id) return new Found(item, visits);
            }
            return new Found(null, visits);
        }
    }
    private static final class Binary extends Lookup {
        @Override String label() { return "binary"; }
        @Override Found find(List<Api.Item> items, int id) {
            int low = 0;
            int high = items.size() - 1;
            int visits = 0;
            while (low <= high) {
                int middle = low + (high - low) / 2;
                Api.Item item = items.get(middle);
                visits++;
                if (item.id() == id) return new Found(item, visits);
                if (item.id() < id) low = middle + 1;
                else high = middle - 1;
            }
            return new Found(null, visits);
        }
    }

    private static void missingNative() throws Exception {
        Process process = new ProcessBuilder(javaTool("java"), "-Djava.library.path=build/empty",
                "-cp", "build/classes", "devbox.tests.NativeChecksum").redirectErrorStream(true).start();
        String output = finish(process);
        assert process.exitValue() != 0 && output.contains("UnsatisfiedLinkError");
    }

    private static void diagnostics() throws Exception {
        CountDownLatch entered = new CountDownLatch(1);
        CountDownLatch release = new CountDownLatch(1);
        Thread worker = new Thread(() -> parkHere(entered, release), "rest-diagnostic-worker");
        worker.start();
        try {
            assert entered.await(5, TimeUnit.SECONDS);
            long deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(5);
            while (worker.getState() != Thread.State.WAITING) {
                if (System.nanoTime() > deadline) throw new AssertionError("worker did not park");
                Thread.onSpinWait();
            }
            Process process = new ProcessBuilder(javaTool("jcmd"), Long.toString(ProcessHandle.current().pid()),
                    "Thread.print").redirectErrorStream(true).start(); // L3-003-jvm-thread-diagnostics
            String dump = finish(process);
            assert process.exitValue() == 0;
            int begin = dump.indexOf("\"rest-diagnostic-worker\"");
            assert begin >= 0 : "diagnostic worker missing";
            int end = dump.indexOf("\n\n", begin);
            String stack = dump.substring(begin, end < 0 ? dump.length() : end);
            assert stack.contains("WAITING") && stack.contains("EngineeringTest.parkHere");
        } finally {
            release.countDown();
            worker.join(5000);
            if (worker.isAlive()) throw new AssertionError("diagnostic worker did not stop");
        }
    }

    private static void parkHere(CountDownLatch entered, CountDownLatch release) {
        entered.countDown();
        try {
            release.await();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("diagnostic worker interrupted", e);
        }
    }

    private static void seedFile() throws Exception {
        Path seed = Path.of("build/seed.txt");
        Files.writeString(seed, "中文\n", StandardCharsets.UTF_8);
        try {
            assert Files.readString(seed, StandardCharsets.UTF_8).strip().equals("中文");
            assert Main.Options.parse(new String[]{"--seed", seed.toString()}).seed().equals(seed);
            Files.writeString(seed, "", StandardCharsets.UTF_8);
            assert Files.size(seed) == 0;
        } finally {
            Files.delete(seed);
        }
        SelfTest.expect(java.nio.file.NoSuchFileException.class,
                () -> Files.readString(seed, StandardCharsets.UTF_8));
    }

    private static String javaTool(String name) {
        return Path.of(System.getProperty("java.home"), "bin", name).toString();
    }

    private static String finish(Process process) throws Exception {
        try {
            // Drain large thread dumps concurrently so the child cannot block on a full pipe.
            try (var pool = java.util.concurrent.Executors.newSingleThreadExecutor()) {
                var reader = pool.submit(() -> {
                    try (var input = process.getInputStream()) {
                        return new String(input.readAllBytes(), StandardCharsets.UTF_8);
                    }
                });
                if (!process.waitFor(15, TimeUnit.SECONDS)) {
                    process.destroyForcibly();
                    throw new AssertionError("probe timeout");
                }
                return reader.get(5, TimeUnit.SECONDS);
            }
        } finally {
            if (process.isAlive()) process.destroyForcibly();
        }
    }
}
