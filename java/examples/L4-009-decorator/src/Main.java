public class Main {
    abstract static class Component {
        abstract String render();
    }

    static final class Text extends Component {
        private final String value;

        Text(String value) {
            this.value = value;
        }

        @Override
        String render() {
            return value;
        }
    }

    abstract static class Decorator extends Component {
        protected final Component component;

        Decorator(Component component) {
            this.component = component;
        }
    }

    static final class Brackets extends Decorator {
        Brackets(Component component) {
            super(component);
        }

        @Override
        String render() {
            return "[" + component.render() + "]";
        }
    }

    static final class Stars extends Decorator {
        Stars(Component component) {
            super(component);
        }

        @Override
        String render() {
            return "*" + component.render() + "*";
        }
    }

    public static void main(String[] args) {
        Component base = new Text("java");
        Component decorated = new Stars(new Brackets(base));
        Component reversed = new Brackets(new Stars(base));
        System.out.println("base: " + base.render());
        System.out.println("two layers: " + decorated.render());
        System.out.println("reversed: " + reversed.render());
    }
}
