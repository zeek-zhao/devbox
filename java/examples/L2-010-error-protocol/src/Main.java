import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.NoSuchFileException;
import java.nio.file.Path;
import java.util.concurrent.TimeUnit;

public class Main {
    public static void main(String[] args) throws Exception {
        if (args.length > 0) {
            runCommand(args[0]);
            return;
        }

        checkChild("normal", 0, "result: 1\n", "");
        System.out.println("normal-exit: 0");
        checkChild("user-error", 2, "", "error: user\n");
        System.out.println("user-error-exit: 2");
        checkChild("missing-document", 3, "", "error: io: missing.txt\n");
        System.out.println("io-error-exit: 3");
        checkChild("internal-error", 1, "", "error: internal: IllegalStateException\n");
        System.out.println("internal-error-exit: 1");
    }

    private static void runCommand(String mode) {
        switch (mode) {
            case "normal" -> System.out.println("result: 1");
            case "user-error" -> fail(2, "error: user");
            case "missing-document" -> {
                try {
                    throw new NoSuchFileException("missing.txt");
                } catch (NoSuchFileException cause) {
                    fail(3, "error: io: " + cause.getFile());
                }
            }
            case "internal-error" -> {
                try {
                    throw new IllegalStateException("index invariant");
                } catch (IllegalStateException cause) {
                    fail(1, "error: internal: " + cause.getClass().getSimpleName());
                }
            }
            default -> throw new IllegalArgumentException("unknown mode");
        }
    }

    private static void fail(int status, String message) {
        System.err.println(message);
        System.exit(status);
    }

    private static void checkChild(
            String mode, int expectedStatus, String expectedOutput, String expectedError)
            throws IOException, InterruptedException {
        String java = Path.of(System.getProperty("java.home"), "bin", "java").toString();
        Process process =
                new ProcessBuilder(
                                java,
                                "-cp",
                                System.getProperty("java.class.path"),
                                Main.class.getName(),
                                mode)
                        .start();
        if (!process.waitFor(5, TimeUnit.SECONDS)) {
            process.destroyForcibly();
            throw new IllegalStateException("child command timed out: " + mode);
        }
        String actualOutput =
                new String(process.getInputStream().readAllBytes(), StandardCharsets.UTF_8);
        String actualError =
                new String(process.getErrorStream().readAllBytes(), StandardCharsets.UTF_8);
        if (process.exitValue() != expectedStatus
                || !actualOutput.equals(expectedOutput)
                || !actualError.equals(expectedError)) {
            throw new IllegalStateException("unexpected child error protocol: " + mode);
        }
    }
}
