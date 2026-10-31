import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.concurrent.TimeUnit;

public class Main {
    public static void main(String[] args) throws Exception {
        Path directory = Path.of(args[0]);
        Path script = directory.resolve("experiment.jsh");
        Path output = directory.resolve("jshell-output.txt");
        Files.writeString(script,
                "int twice(int value) { return value * 2; }\n"
                        + "if (twice(21) != 42) throw new AssertionError(\"bad result\");\n"
                        + "System.out.println(\"repl: ok\");\n"
                        + "/exit\n",
                StandardCharsets.UTF_8);

        Path jshell = Path.of(System.getProperty("java.home"), "bin", "jshell");
        Process process = new ProcessBuilder(jshell.toString(), "--feedback", "silent",
                "-J-Djava.util.prefs.userRoot=" + directory.resolve("prefs"))
                .redirectInput(script.toFile())
                .redirectErrorStream(true)
                .redirectOutput(output.toFile())
                .start();
        if (!process.waitFor(10, TimeUnit.SECONDS)) {
            process.destroyForcibly();
            throw new IllegalStateException("jshell timed out");
        }
        String diagnostics = Files.readString(output, StandardCharsets.UTF_8);
        if (process.exitValue() != 0
                || diagnostics.lines().filter(line -> line.contains("repl: ok")).count() != 1
                || diagnostics.contains("Error:")
                || diagnostics.contains("Exception")) {
            throw new IllegalStateException("jshell batch verification failed: " + diagnostics);
        }
        System.out.println("repl: ok");

        if (twice(21) != 42) {
            throw new AssertionError("compiled expression failed");
        }
        System.out.println("compiled: ok");
    }

    private static int twice(int value) {
        return value * 2;
    }
}
