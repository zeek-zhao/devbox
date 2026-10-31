public class Main {
    enum Level { INFO, WARNING, ERROR }

    abstract static class Handler {
        private final Handler next;

        Handler(Handler next) {
            this.next = next;
        }

        final String handle(Level level) {
            if (accepts(level)) {
                return label();
            }
            if (next == null) {
                throw new IllegalArgumentException("Unhandled level: " + level);
            }
            return next.handle(level);
        }

        abstract boolean accepts(Level level);
        abstract String label();
    }

    static final class InfoHandler extends Handler {
        InfoHandler(Handler next) { super(next); }
        @Override boolean accepts(Level level) { return level == Level.INFO; }
        @Override String label() { return "info-handler"; }
    }

    static final class WarningHandler extends Handler {
        WarningHandler(Handler next) { super(next); }
        @Override boolean accepts(Level level) { return level == Level.WARNING; }
        @Override String label() { return "warning-handler"; }
    }

    static final class ErrorHandler extends Handler {
        ErrorHandler(Handler next) { super(next); }
        @Override boolean accepts(Level level) { return level == Level.ERROR; }
        @Override String label() { return "error-handler"; }
    }

    public static void main(String[] args) {
        Handler chain = new InfoHandler(new WarningHandler(new ErrorHandler(null)));
        for (Level level : Level.values()) {
            System.out.println(level + " -> " + chain.handle(level));
        }
    }
}
