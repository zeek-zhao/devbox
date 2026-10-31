import java.io.IOException;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Locale;
import java.util.function.Function;
import java.util.stream.Collectors;
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

    public static void main(String[] args) throws IOException {
        String prefix = "term:";
        Function<String, String> capture = text -> prefix + text;
        List<String> words = List.of("oak", "river");
        List<Integer> lengths = words.stream()
                .map(String::length)
                .collect(Collectors.toList());
        Path probes = Path.of(args[0], "probes");

        System.out.println("captured value=" + capture.apply("search"));
        System.out.println("method reference lengths=" + lengths);
        System.out.println("rejects reassigned capture=" + rejected(
                "import java.util.function.*; class Probe { void test() { "
                        + "String value = \"stable\"; Runnable action = () -> System.out.println(value); "
                        + "value = \"changed\"; } }",
                probes));
    }
}
