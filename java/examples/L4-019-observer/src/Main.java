import java.util.ArrayList;
import java.util.List;

public class Main {
    interface Observer {
        void updated(int version);
    }

    static final class Index {
        private final List<Observer> listeners = new ArrayList<>();
        private int version;

        void add(Observer observer) {
            listeners.add(observer);
        }

        void remove(Observer observer) {
            listeners.remove(observer);
        }

        void update() {
            version++;
            for (Observer observer : List.copyOf(listeners)) {
                observer.updated(version);
            }
        }
    }

    static final class Cache implements Observer {
        @Override
        public void updated(int version) {
            System.out.println("cache invalidated: " + version);
        }
    }

    static final class Audit implements Observer {
        @Override
        public void updated(int version) {
            System.out.println("audit recorded: " + version);
        }
    }

    public static void main(String[] args) {
        Index index = new Index();
        Observer cache = new Cache();
        Observer audit = new Audit();
        index.add(cache);
        index.add(audit);
        index.update();
        index.remove(cache);
        index.update();
        index.remove(audit);
        index.update();
    }
}
