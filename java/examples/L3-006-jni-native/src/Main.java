import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.util.concurrent.TimeUnit;

public class Main {
    public static void main(String[] args) throws Exception {
        if (args.length > 0 && args[0].equals("missing-library")) {
            try {
                System.loadLibrary("devbox_missing_probe");
            } catch (UnsatisfiedLinkError expected) {
                System.err.println("missing-library: UnsatisfiedLinkError");
                System.exit(1);
            }
            throw new IllegalStateException("missing native library was accepted");
        }

        System.loadLibrary("probe");
        int result = NativeProbe.add(2, 3);
        if (result != 5) {
            throw new IllegalStateException("native result mismatch");
        }
        checkMissingLibrary(args[0]);
        System.out.println("jni-add: " + result);
        System.out.println("missing-library-rejected: true");
    }

    private static void checkMissingLibrary(String directory)
            throws IOException, InterruptedException {
        String java = Path.of(System.getProperty("java.home"), "bin", "java").toString();
        String classpath = System.getProperty("java.class.path");
        Process process =
                new ProcessBuilder(
                                java,
                                "-Djava.library.path=" + directory,
                                "-cp",
                                classpath,
                                Main.class.getName(),
                                "missing-library")
                        .redirectErrorStream(true)
                        .start();
        if (!process.waitFor(5, TimeUnit.SECONDS)) {
            process.destroyForcibly();
            throw new IllegalStateException("missing-library probe timed out");
        }
        String output = new String(process.getInputStream().readAllBytes(), StandardCharsets.UTF_8);
        if (process.exitValue() == 0 || !output.equals("missing-library: UnsatisfiedLinkError\n")) {
            throw new IllegalStateException("unexpected missing-library probe result: " + output);
        }
    }
}
