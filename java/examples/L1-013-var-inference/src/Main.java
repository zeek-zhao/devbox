import java.io.IOException;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Locale;

import javax.tools.DiagnosticCollector;
import javax.tools.JavaFileObject;
import javax.tools.SimpleJavaFileObject;
import javax.tools.StandardJavaFileManager;
import javax.tools.ToolProvider;

public class Main {
    private static final class Source extends SimpleJavaFileObject {
        private final String source;

        Source(String source) {
            super(URI.create("string:///Probe.java"), Kind.SOURCE);
            this.source = source;
        }

        @Override
        public CharSequence getCharContent(boolean ignoreEncodingErrors) {
            return source;
        }
    }

    private static boolean rejected(String source, Path output) throws IOException {
        var compiler = ToolProvider.getSystemJavaCompiler();
        if (compiler == null) {
            throw new IllegalStateException("JDK compiler is unavailable");
        }
        Files.createDirectories(output);
        var diagnostics = new DiagnosticCollector<JavaFileObject>();
        try (StandardJavaFileManager manager =
                compiler.getStandardFileManager(diagnostics, Locale.ROOT, StandardCharsets.UTF_8)) {
            boolean compiled =
                    Boolean.TRUE.equals(
                            compiler.getTask(
                                            null,
                                            manager,
                                            diagnostics,
                                            List.of("-proc:none", "-d", output.toString()),
                                            null,
                                            List.of(new Source(source)))
                                    .call());
            return !compiled;
        }
    }

    public static void main(String[] args) throws IOException {
        var count = 4;
        String missing = null;
        java.util.function.IntUnaryOperator twice = value -> value * 2;
        Path probes = Path.of(args[0], "probes");

        System.out.println("inferred integer=" + count);
        System.out.println("explicit null=" + (missing == null));
        System.out.println("explicit lambda result=" + twice.applyAsInt(3));
        System.out.println(
                "var rejects null="
                        + rejected("class Probe { void test() { var value = null; } }", probes));
        System.out.println(
                "var rejects lambda="
                        + rejected(
                                "class Probe { void test() { var action = () -> 1; } }", probes));
        System.out.println(
                "var rejects field=" + rejected("class Probe { var field = 1; }", probes));
    }
}
