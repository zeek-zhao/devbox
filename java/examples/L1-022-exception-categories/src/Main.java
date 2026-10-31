import java.net.URI;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Arrays;
import javax.tools.JavaCompiler;
import javax.tools.SimpleJavaFileObject;
import javax.tools.ToolProvider;

public class Main {
    private static boolean compiles(String className, String body) {
        JavaCompiler compiler = ToolProvider.getSystemJavaCompiler();
        if (compiler == null) {
            throw new IllegalStateException("JDK compiler is unavailable");
        }
        String source = "import java.io.IOException; import java.nio.file.*; "
                + "class " + className + " { " + body + " }";
        SimpleJavaFileObject file = new SimpleJavaFileObject(
                URI.create("string:///" + className + ".java"),
                SimpleJavaFileObject.Kind.SOURCE) {
            @Override
            public CharSequence getCharContent(boolean ignoreEncodingErrors) {
                return source;
            }
        };
        Path output = Path.of(System.getProperty("java.class.path"));
        try {
            Files.createDirectories(output);
        } catch (java.io.IOException exception) {
            throw new IllegalStateException("Could not prepare compiler output", exception);
        }
        return compiler.getTask(null, null, diagnostic -> { }, Arrays.asList(
                "-proc:none", "-d", output.toString()), null, java.util.List.of(file)).call();
    }

    public static void main(String[] args) {
        boolean uncheckedWithoutDeclaration = compiles("UncheckedProbe",
                "static int parse(String value) { return Integer.parseInt(value); }");
        boolean checkedWithoutHandling = compiles("UncheckedCheckedProbe",
                "static String read(Path path) { return Files.readString(path); }");
        boolean checkedHandled = compiles("HandledProbe",
                "static String read(Path path) throws IOException { return Files.readString(path); }");

        System.out.println("unchecked-needs-no-declaration=" + uncheckedWithoutDeclaration);
        System.out.println("checked-unhandled-rejected=" + !checkedWithoutHandling);
        System.out.println("checked-declared-accepted=" + checkedHandled);

        try {
            throw new java.io.IOException("read failed");
        } catch (java.io.IOException exception) {
            System.out.println("checked-caught=" + exception.getClass().getSimpleName());
        }
        try {
            Integer.parseInt("not-a-number");
        } catch (NumberFormatException exception) {
            System.out.println("unchecked-caught=" + exception.getClass().getSimpleName());
        }
    }
}
