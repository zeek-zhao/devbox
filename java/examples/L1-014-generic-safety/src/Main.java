import java.io.IOException;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
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
            boolean compiled = Boolean.TRUE.equals(compiler.getTask(
                    null, manager, diagnostics,
                    List.of("-proc:none", "-d", output.toString()),
                    null, List.of(new Source(source))).call());
            return !compiled;
        }
    }

    private static <T> T first(List<T> values) {
        return values.get(0);
    }

    public static void main(String[] args) throws IOException {
        List<String> words = new ArrayList<>(List.of("index"));
        List<Integer> numbers = new ArrayList<>(List.of(7));
        Path probes = Path.of(args[0], "probes");

        System.out.println("first string=" + first(words));
        System.out.println("first integer=" + first(numbers));
        System.out.println("rejects wrong element=" + rejected(
                "import java.util.*; class Probe { void test() { "
                        + "List<String> values = new ArrayList<>(); values.add(7); } }",
                probes));
        System.out.println("rejects covariant list=" + rejected(
                "import java.util.*; class Probe { void test() { "
                        + "List<Integer> integers = new ArrayList<>(); "
                        + "List<Number> numbers = integers; } }",
                probes));
    }
}
