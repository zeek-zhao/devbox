import java.util.List;

public final class Cli {
    private static final List<String> ITEMS = List.of("alpha", "beta", "gamma");
    private static final String USAGE = "usage: cli --limit <0..3>";

    private Cli() {}

    public static void main(String[] args) {
        if (args.length == 1 && "--help".equals(args[0])) {
            System.out.println(USAGE);
            return;
        }
        if (args.length != 2 || !"--limit".equals(args[0])) {
            fail();
        }

        int limit;
        try {
            limit = Integer.parseInt(args[1]);
        } catch (NumberFormatException exception) {
            fail();
            return;
        }
        if (limit < 0 || limit > ITEMS.size()) {
            fail();
        }
        System.out.println("items=" + ITEMS.subList(0, limit));
    }

    private static void fail() {
        System.err.println("error: " + USAGE);
        System.exit(2);
    }
}
