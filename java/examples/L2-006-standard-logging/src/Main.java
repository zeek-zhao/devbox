import java.util.logging.Handler;
import java.util.logging.Level;
import java.util.logging.LogRecord;
import java.util.logging.Logger;
import java.util.logging.StreamHandler;

public final class Main {
    private static final class StableFormatter extends java.util.logging.Formatter {
        @Override
        public String format(LogRecord record) {
            return record.getLevel().getName()
                    + ":"
                    + formatMessage(record)
                    + System.lineSeparator();
        }
    }

    private Main() {}

    public static void main(String[] args) {
        Logger logger = Logger.getLogger("devbox.example");
        logger.setUseParentHandlers(false);
        logger.setLevel(Level.ALL);

        Handler handler =
                new StreamHandler(System.err, new StableFormatter()) {
                    @Override
                    public synchronized void publish(LogRecord record) {
                        super.publish(record);
                        flush();
                    }
                };
        handler.setLevel(Level.INFO);
        logger.addHandler(handler);

        logger.info("index-ready");
        logger.fine("hidden-detail");
        System.out.println("business=ready");
        logger.removeHandler(handler);
        handler.close();
    }
}
