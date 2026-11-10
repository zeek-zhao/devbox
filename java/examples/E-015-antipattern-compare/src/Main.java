import java.util.logging.Handler;
import java.util.logging.Level;
import java.util.logging.LogRecord;
import java.util.logging.Logger;

public class Main {
    static final class TransientException extends RuntimeException {
        TransientException(String message) {
            super(message);
        }
    }

    static String opThatFails() {
        throw new TransientException("storage busy");
    }

    static String antiSwallows() {
        try {
            return opThatFails();
        } catch (RuntimeException err) {
            return "swallowed (bug invisible)";
        }
    }

    static String antiClassifiesByText() {
        try {
            return opThatFails();
        } catch (RuntimeException err) {
            boolean timeoutLike = err.getMessage().contains("timeout");
            return timeoutLike ? "timeout-like" : "other";
        }
    }

    static String fixedClassifiesByType() {
        try {
            return opThatFails();
        } catch (TransientException err) {
            return "TRANSIENT";
        } catch (RuntimeException err) {
            return "INTERNAL";
        }
    }

    static void fixedLogsStructured(Logger logger, RuntimeException err) {
        logger.log(
                Level.WARNING,
                () ->
                        String.format(
                                "{\"code\": \"%s\", \"message\": \"%s\", \"type\": \"%s\"}",
                                "TRANSIENT", err.getMessage(), err.getClass().getSimpleName()));
    }

    public static void main(String[] args) {
        System.out.println("anti-1: " + antiSwallows() + " -> wrong");
        Logger logger = Logger.getLogger("app");
        logger.setUseParentHandlers(false);
        logger.addHandler(
                new Handler() {
                    @Override
                    public void publish(LogRecord record) {
                        System.out.println("fix-1: " + record.getMessage() + " -> logged, visible");
                    }

                    @Override
                    public void flush() {
                        // no-op
                    }

                    @Override
                    public void close() {
                        // no-op
                    }
                });
        fixedLogsStructured(logger, new TransientException("storage busy"));
        System.out.println(
                "anti-2: " + antiClassifiesByText() + " (classified by message text) -> wrong");
        System.out.println("fix-2: " + fixedClassifiesByType() + " (classified by type) -> stable");
        System.out.println(
                "rule: never swallow silently; classify by type; log one structured line");
    }
}
