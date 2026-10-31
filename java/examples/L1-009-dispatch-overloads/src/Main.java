class QueryHandler {
    String handle() {
        return "base";
    }

    String select(Object value) {
        return "object";
    }

    String select(String value) {
        return "string";
    }
}

final class DocumentHandler extends QueryHandler {
    @Override
    String handle() {
        return "document";
    }
}

public class Main {
    public static void main(String[] args) {
        QueryHandler handler = new DocumentHandler();
        String query = "term";
        Object queryAsObject = query;
        System.out.println("overridden method: " + handler.handle());
        System.out.println("String overload: " + handler.select(query));
        System.out.println("Object overload: " + handler.select(queryAsObject));
    }
}
