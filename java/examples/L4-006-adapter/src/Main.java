public class Main {
    interface Query {
        String find(String term);
    }

    static class LegacySearch {
        String lookup(String term) {
            return "legacy[" + term + "]";
        }
    }

    static final class ObjectAdapter implements Query {
        private final LegacySearch target;

        ObjectAdapter(LegacySearch target) {
            this.target = target;
        }

        @Override
        public String find(String term) {
            return target.lookup(term);
        }
    }

    static final class ClassAdapter extends LegacySearch implements Query {
        @Override
        public String find(String term) {
            return lookup(term);
        }
    }

    public static void main(String[] args) {
        LegacySearch legacy = new LegacySearch();
        Query objectAdapter = new ObjectAdapter(legacy);
        Query classAdapter = new ClassAdapter();
        System.out.println("object: " + objectAdapter.find("java"));
        System.out.println("class: " + classAdapter.find("java"));
        System.out.println(
                "same result: "
                        + objectAdapter.find("patterns").equals(classAdapter.find("patterns")));
    }
}
