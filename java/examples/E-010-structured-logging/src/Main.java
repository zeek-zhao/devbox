public class Main {
    private static int seq;

    static String escape(String raw) {
        return raw.replace("\\", "\\\\").replace("\"", "\\\"");
    }

    static void log(String level, String code, String message) {
        seq++;
        System.out.println(
                "{\"code\": \""
                        + code
                        + "\", \"level\": \""
                        + level
                        + "\", \"message\": \""
                        + escape(message)
                        + "\", \"seq\": "
                        + seq
                        + "}");
    }

    public static void main(String[] args) {
        log("ERROR", "TRANSIENT", "db unavailable");
        log("ERROR", "VALIDATION", "field age must be a positive integer");
        log("INFO", "NONE", "handled 2 errors, service up");
        System.out.println("rule: one JSON per line; error class is a field, not a message prefix");
    }
}
