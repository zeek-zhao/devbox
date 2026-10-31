import java.util.ArrayList;
import java.util.List;

public class Main {
    interface Component {
        void print(String indent);
    }

    record Leaf(String name) implements Component {
        @Override
        public void print(String indent) {
            System.out.println(indent + "leaf: " + name);
        }
    }

    static final class Group implements Component {
        private final String name;
        private final List<Component> children = new ArrayList<>();

        Group(String name) {
            this.name = name;
        }

        Group add(Component child) {
            children.add(child);
            return this;
        }

        @Override
        public void print(String indent) {
            System.out.println(indent + "group: " + name);
            for (Component child : children) {
                child.print(indent + "  ");
            }
        }
    }

    public static void main(String[] args) {
        Group nested = new Group("nested").add(new Leaf("b")).add(new Leaf("c"));
        Component root = new Group("root").add(new Leaf("a")).add(nested).add(new Leaf("d"));
        root.print("");
    }
}
