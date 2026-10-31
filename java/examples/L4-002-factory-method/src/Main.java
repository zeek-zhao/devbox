public class Main {
    interface Product {
        String name();
    }

    static final class JsonProduct implements Product {
        @Override
        public String name() {
            return "json";
        }
    }

    static final class TextProduct implements Product {
        @Override
        public String name() {
            return "text";
        }
    }

    abstract static class Factory<P extends Product> {
        abstract P create();
    }

    static final class JsonFactory extends Factory<JsonProduct> {
        @Override
        JsonProduct create() {
            return new JsonProduct();
        }
    }

    static final class TextFactory extends Factory<TextProduct> {
        @Override
        TextProduct create() {
            return new TextProduct();
        }
    }

    private static <P extends Product> void show(Factory<P> factory) {
        Product product = factory.create();
        System.out.println("product: " + product.name());
    }

    public static void main(String[] args) {
        Factory<JsonProduct> json = new JsonFactory();
        Factory<TextProduct> text = new TextFactory();
        show(json);
        show(text);
    }
}
