import java.util.Objects;

public class Main {
    static int normalizeAge(int age) {
        assert age >= 0 && age <= 150 : "internal invariant broken: age=" + age;
        return age;
    }

    static String register(String id, int amount) {
        Objects.requireNonNull(id, "id is required");
        if (amount <= 0) {
            throw new IllegalArgumentException("amount must be positive");
        }
        return "registered " + id + " amount=" + amount;
    }

    public static void main(String[] args) {
        System.out.println("assert-enabled: " + Main.class.desiredAssertionStatus());

        try {
            normalizeAge(-1);
        } catch (AssertionError err) {
            System.out.println(
                    "internal-invariant: "
                            + err.getClass().getSimpleName()
                            + " caught (assertions guard internal bugs)");
        }

        try {
            register(null, 5);
        } catch (NullPointerException err) {
            System.out.println(
                    "null-contract: " + err.getClass().getSimpleName() + ": " + err.getMessage());
        }

        try {
            register("doc-7", 0);
        } catch (IllegalArgumentException err) {
            System.out.println(
                    "public-api: " + err.getClass().getSimpleName() + ": " + err.getMessage());
        }

        System.out.println(
                "rule: assert for internal invariants, typed exceptions for API contracts");
    }
}
