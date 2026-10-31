package client;

import app.SearchFacade;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import javax.tools.JavaCompiler;
import javax.tools.ToolProvider;

public class Main {
    public static void main(String[] args) throws Exception {
        System.out.println("service-result: " + SearchFacade.create().find("java"));

        Path source = Path.of(args[0], "BoundaryProbe.java");
        Files.writeString(source,
                "package client; class BoundaryProbe { "
                        + "app.SearchServiceImpl implementation; }",
                StandardCharsets.UTF_8);
        JavaCompiler compiler = ToolProvider.getSystemJavaCompiler();
        if (compiler == null) {
            throw new IllegalStateException("JDK compiler is unavailable");
        }
        Path probeClasses = Path.of(args[0], "probe-classes");
        Files.createDirectories(probeClasses);
        ByteArrayOutputStream diagnostics = new ByteArrayOutputStream();
        int result = compiler.run(null, null, diagnostics,
                "-classpath", System.getProperty("java.class.path"),
                "-d", probeClasses.toString(),
                source.toString());
        if (result == 0) {
            throw new IllegalStateException(
                    "package-private implementation was accessible: "
                            + diagnostics.toString(StandardCharsets.UTF_8));
        }
        System.out.println("implementation-hidden: true");
    }
}
