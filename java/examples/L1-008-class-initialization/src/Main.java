import java.util.ArrayList;
import java.util.List;

final class IndexConfig {
    private static int instanceCount = 0;
    private int localCount = 0;
    private final List<String> tags = new ArrayList<>();

    IndexConfig() {
        instanceCount++;
    }

    void increment() {
        localCount++;
    }

    int localCount() {
        return localCount;
    }

    static int instanceCount() {
        return instanceCount;
    }

    void addTag(String tag) {
        tags.add(tag);
    }

    String tags() {
        return String.join(",", tags);
    }
}

public class Main {
    public static void main(String[] args) {
        IndexConfig first = new IndexConfig();
        IndexConfig second = new IndexConfig();
        first.increment();
        first.increment();
        second.increment();
        first.addTag("ready");
        System.out.println("first local count: " + first.localCount());
        System.out.println("second local count: " + second.localCount());
        System.out.println("shared instance count: " + IndexConfig.instanceCount());
        System.out.println("final reference contents: " + first.tags());
    }
}
