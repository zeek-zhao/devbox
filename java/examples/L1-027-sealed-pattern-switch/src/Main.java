public class Main {
    private sealed interface Query permits ById, ByName {}

    private record ById(int value) implements Query {}

    private record ByName(String value) implements Query {}

    private static String describe(Query query) {
        return switch (query) {
            case ById byId -> "id:" + byId.value();
            case ByName byName -> "name:" + byName.value();
            case null -> "empty";
        };
    }

    public static void main(String[] args) {
        System.out.println("by-id=" + describe(new ById(7)));
        System.out.println("by-name=" + describe(new ByName("guide")));
        System.out.println("null=" + describe(null));
    }
}
