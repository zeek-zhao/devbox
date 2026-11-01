import java.util.List;

public class Main {
    interface Element {
        <R> R accept(Visitor<R> visitor);
    }

    interface Visitor<R> {
        R visit(Text text);

        R visit(NumberNode number);
    }

    record Text(String value) implements Element {
        @Override
        public <R> R accept(Visitor<R> visitor) {
            return visitor.visit(this);
        }
    }

    record NumberNode(int value) implements Element {
        @Override
        public <R> R accept(Visitor<R> visitor) {
            return visitor.visit(this);
        }
    }

    static final class Render implements Visitor<String> {
        @Override
        public String visit(Text text) {
            return "render/text: " + text.value();
        }

        @Override
        public String visit(NumberNode number) {
            return "render/number: " + number.value();
        }
    }

    record Measurement(String label, int value) {}

    static final class Measure implements Visitor<Measurement> {
        @Override
        public Measurement visit(Text text) {
            return new Measurement("measure/text", text.value().length());
        }

        @Override
        public Measurement visit(NumberNode number) {
            return new Measurement("measure/number", Integer.toString(number.value()).length());
        }
    }

    public static void main(String[] args) {
        List<Element> elements = List.of(new Text("java"), new NumberNode(21));
        Visitor<String> render = new Render();
        Visitor<Measurement> measure = new Measure();
        for (Element element : elements) {
            String rendered = element.accept(render);
            System.out.println(rendered);
        }
        for (Element element : elements) {
            Measurement measurement = element.accept(measure);
            System.out.println(measurement.label() + ": " + measurement.value());
        }
    }
}
