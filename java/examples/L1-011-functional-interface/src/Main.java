interface TextRule {
    String apply(String text);
}

public class Main {
    private final String prefix = "outer:";

    private void demonstrate() {
        TextRule lambda = text -> this.prefix + text;
        TextRule anonymous = new TextRule() {
            private final String prefix = "callback:";

            @Override
            public String apply(String text) {
                return this.prefix + text;
            }
        };

        System.out.println("lambda=" + lambda.apply("word"));
        System.out.println("anonymous=" + anonymous.apply("word"));
    }

    public static void main(String[] args) {
        new Main().demonstrate();
    }
}
