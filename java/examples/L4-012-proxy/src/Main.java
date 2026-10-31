import java.util.function.Supplier;

public class Main {
    interface Query {
        String execute(String term);
    }

    static final class RealQuery implements Query {
        private static int constructions;

        RealQuery() {
            constructions++;
        }

        @Override
        public String execute(String term) {
            System.out.println("target: " + term);
            return "result[" + term + "]";
        }
    }

    static final class QueryProxy implements Query {
        private final Supplier<? extends Query> factory;
        private Query target;
        private int calls;

        QueryProxy(Supplier<? extends Query> factory) {
            this.factory = factory;
        }

        @Override
        public String execute(String term) {
            calls++;
            System.out.println("before: " + calls);
            if (target == null) {
                target = factory.get();
            }
            String result = target.execute(term);
            System.out.println("after: " + calls);
            return result;
        }
    }

    public static void main(String[] args) {
        Query proxy = new QueryProxy(RealQuery::new);
        System.out.println("constructed before access: " + RealQuery.constructions);
        System.out.println("returned: " + proxy.execute("java"));
        System.out.println("returned: " + proxy.execute("patterns"));
        System.out.println("constructed after access: " + RealQuery.constructions);
    }
}
