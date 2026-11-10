public class Probe {
    public static void main(String[] args) {
        String mode = args.length > 0 ? args[0] : "usage";
        switch (mode) {
            case "usage":
                System.err.println("error: unknown option --limit");
                System.err.println("probe: usage error -> exit 2 (stderr carries detail)");
                System.exit(2);
                return;
            case "data":
                System.err.println("error: record 3 has negative amount");
                System.err.println("probe: data error -> exit 1 (stderr carries detail)");
                System.exit(1);
                return;
            default:
                System.out.println("probe: ok -> exit 0");
                return;
        }
    }
}
