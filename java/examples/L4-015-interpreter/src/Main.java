import java.util.Map;

public class Main {
    interface Expression {
        int interpret(Map<String, Integer> context);
    }

    record Literal(int value) implements Expression {
        @Override
        public int interpret(Map<String, Integer> context) {
            return value;
        }
    }

    record Variable(String name) implements Expression {
        @Override
        public int interpret(Map<String, Integer> context) {
            Integer value = context.get(name);
            if (value == null) {
                throw new IllegalArgumentException("Undefined variable: " + name);
            }
            return value;
        }
    }

    record Add(Expression left, Expression right) implements Expression {
        @Override
        public int interpret(Map<String, Integer> context) {
            return left.interpret(context) + right.interpret(context);
        }
    }

    record Multiply(Expression left, Expression right) implements Expression {
        @Override
        public int interpret(Map<String, Integer> context) {
            return left.interpret(context) * right.interpret(context);
        }
    }

    public static void main(String[] args) {
        Expression expression =
                new Multiply(new Add(new Variable("x"), new Literal(2)), new Literal(3));
        System.out.println("(x + 2) * 3, x=4: " + expression.interpret(Map.of("x", 4)));
        System.out.println("(x + 2) * 3, x=5: " + expression.interpret(Map.of("x", 5)));
    }
}
