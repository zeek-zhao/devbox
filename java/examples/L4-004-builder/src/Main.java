import java.util.ArrayList;
import java.util.List;

public class Main {
    static final class Query {
        private final String term;
        private final int limit;
        private final List<String> fields;

        private Query(Builder builder) {
            term = builder.term;
            limit = builder.limit;
            fields = List.copyOf(builder.fields);
        }

        String summary() {
            return term + "/" + limit + "/" + fields;
        }

        List<String> fields() {
            return fields;
        }

        static final class Builder {
            private String term;
            private int limit = 10;
            private final List<String> fields = new ArrayList<>();

            Builder term(String term) {
                this.term = term;
                return this;
            }

            Builder limit(int limit) {
                if (limit <= 0) {
                    throw new IllegalArgumentException("limit must be positive");
                }
                this.limit = limit;
                return this;
            }

            Builder field(String field) {
                fields.add(field);
                return this;
            }

            Query build() {
                if (term == null || term.isBlank()) {
                    throw new IllegalStateException("term is required");
                }
                return new Query(this);
            }
        }
    }

    public static void main(String[] args) {
        Query.Builder builder = new Query.Builder().term("java").limit(3).field("title");
        Query query = builder.build();
        System.out.println("query: " + query.summary());
        builder.term("changed").limit(5).field("body");
        System.out.println("after builder change: " + query.summary());
        try {
            query.fields().add("forbidden");
            throw new AssertionError("Query fields were mutable");
        } catch (UnsupportedOperationException expected) {
            System.out.println("immutable fields: " + expected.getClass().getSimpleName());
        }
        try {
            new Query.Builder().field("title").build();
            throw new AssertionError("Missing term was accepted");
        } catch (IllegalStateException expected) {
            System.out.println("missing term: " + expected.getClass().getSimpleName());
        }
    }
}
