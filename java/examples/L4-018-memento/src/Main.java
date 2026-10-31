import java.util.ArrayList;
import java.util.List;

public class Main {
    static final class Session {
        private String query;
        private final List<String> filters = new ArrayList<>();

        private record Memento(String query, List<String> filters) {
            private Memento {
                filters = List.copyOf(filters);
            }
        }

        Session(String query) { this.query = query; }
        void query(String value) { query = value; }
        void addFilter(String filter) { filters.add(filter); }
        Memento save() { return new Memento(query, filters); }
        void restore(Memento snapshot) {
            query = snapshot.query();
            filters.clear();
            filters.addAll(snapshot.filters());
        }
        String describe() { return query + " " + filters; }
    }

    public static void main(String[] args) {
        Session session = new Session("java");
        session.addFilter("open");
        Session.Memento saved = session.save();
        System.out.println("saved: " + session.describe());
        session.query("patterns");
        session.addFilter("recent");
        System.out.println("changed: " + session.describe());
        session.restore(saved);
        System.out.println("restored: " + session.describe());
        session.addFilter("mine");
        System.out.println("edited again: " + session.describe());
        session.restore(saved);
        System.out.println("restored again: " + session.describe());
    }
}
