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

    private static double total(List<? extends Number> source) {
        double result = 0;
        for (Number value : source) {
            result += value.doubleValue();
        }
        return result;
    }

    private static void addOne(List<? super Integer> target) {
        target.add(8);
    }

    public static void main(String[] args) throws IOException {
        List<Double> source = List.of(1.5, 2.5);
        List<Number> target = new ArrayList<>();
        addOne(target);
        Object first = target.get(0);
        Path probes = Path.of(args[0], "probes");

        System.out.println("extends source total=" + total(source));
        System.out.println("super target first=" + first);
        System.out.println(
                "extends rejects write="
                        + rejected(
                                "import java.util.*; class Probe { void test() { List<? extends"
                                    + " Number> values = new ArrayList<Integer>(); values.add(1); }"
                                    + " }",
                                probes));
        System.out.println("super accepts integer write=" + (first instanceof Integer));
    }
}
