import java.util.HashSet;
import java.util.Set;

class FixedHashBase {
    private final int fixedHash;

    FixedHashBase(int fixedHash) {
        this.fixedHash = fixedHash;
    }

    @Override
    public int hashCode() {
        return fixedHash;
    }
}

final class FixedHashKey extends FixedHashBase {
    private final String value;

    FixedHashKey(String value, int fixedHash) {
        super(fixedHash);
        this.value = value;
    }

    @Override
    public boolean equals(Object other) {
        return other instanceof FixedHashKey key && value.equals(key.value);
    }
}

final class StableKey {
    private final String value;

    StableKey(String value) {
        this.value = value;
    }

    @Override
    public boolean equals(Object other) {
        return other instanceof StableKey key && value.equals(key.value);
    }

    @Override
    public int hashCode() {
        return value.hashCode();
    }
}

public class Main {
    public static void main(String[] args) {
        Set<FixedHashKey> inconsistent = new HashSet<>();
        inconsistent.add(new FixedHashKey("doc", 1));
        System.out.println("inconsistent hash lookup: "
                + inconsistent.contains(new FixedHashKey("doc", 2)));

        Set<StableKey> consistent = new HashSet<>();
        consistent.add(new StableKey("doc"));
        consistent.add(new StableKey("doc"));
        System.out.println("consistent size: " + consistent.size());
        System.out.println("consistent lookup: " + consistent.contains(new StableKey("doc")));
    }
}
