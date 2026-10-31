import devbox.rest.Api;
import devbox.rest.HttpApp;
import devbox.rest.SelfCheck;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

/** Command boundary; the service itself never exits the process. */
public final class Main {
    private Main() {}

    public static void main(String[] args) {
        try {
            var options = Options.parse(args); // L1-013-var-inference
            if (options.help()) {
                System.out.println("usage: java -jar app.jar [--port 8080] [--seed FILE] | --self-check");
            } else if (options.selfCheck()) {
                SelfCheck.run(System.out);
            } else {
                Api api = Api.create(); // L2-001-packages-classpath
                if (options.seed() != null) {
                    String name = Files.readString(options.seed(), StandardCharsets.UTF_8).strip(); // L2-008-files-utf-eight
                    var result = api.handle(new Api.Request("POST", "/items", devbox.rest.Json.name(name)));
                    if (result.status() != 201) {
                        throw new IllegalArgumentException("invalid seed: " + result.body());
                    }
                }
                HttpApp app = HttpApp.start(api, options.port());
                Runtime.getRuntime().addShutdownHook(new Thread(app::close, "rest-shutdown"));
                System.out.println("REST ready");
            }
        } catch (IllegalArgumentException e) {
            System.err.println("input: " + e.getMessage());
            System.exit(2);
        } catch (IOException e) { // L1-022-exception-categories
            System.err.println("io: " + e.getClass().getSimpleName() + ": " + e.getMessage());
            System.exit(3); // L2-010-error-protocol
        }
    }

    record Options(boolean help, boolean selfCheck, int port, Path seed) {
        static Options parse(String[] args) { // L2-007-cli-parser
            boolean help = false;
            boolean check = false;
            int port = 8080;
            Path seed = null;
            boolean portSet = false;
            for (int i = 0; i < args.length; i++) { // L1-007-array-boundaries
                switch (args[i]) {
                    case "--help" -> help = true;
                    case "--self-check" -> check = true;
                    case "--port" -> {
                        if (++i == args.length) throw new IllegalArgumentException("--port needs a value");
                        port = Integer.parseInt(args[i]);
                        if (port < 1 || port > 65535) throw new IllegalArgumentException("port must be 1..65535");
                        portSet = true;
                    }
                    case "--seed" -> {
                        if (++i == args.length) throw new IllegalArgumentException("--seed needs a file");
                        seed = Path.of(args[i]);
                    }
                    default -> throw new IllegalArgumentException("unknown option: " + args[i]);
                }
            }
            if ((check && (portSet || seed != null || help)) || (help && (portSet || seed != null))) {
                throw new IllegalArgumentException("exclusive mode options");
            }
            return new Options(help, check, port, seed);
        }
    }
}
