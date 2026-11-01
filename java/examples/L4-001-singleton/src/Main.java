import java.lang.reflect.Constructor;

public class Main {
    public static void main(String[] args) throws ReflectiveOperationException {
        Config first = Config.instance();
        Config second = Config.instance();
        System.out.println("same instance: " + (first == second));
        first.setValue("shared");
        System.out.println("second value: " + second.value());

        Constructor<Config> constructor = Config.class.getDeclaredConstructor();
        try {
            constructor.newInstance();
            throw new AssertionError("Private constructor was accessible");
        } catch (IllegalAccessException expected) {
            System.out.println("reflection: " + expected.getClass().getSimpleName());
        }
    }
}

final class Config {
    private String value = "default";

    private Config() {}

    private static final class Holder {
        private static final Config INSTANCE = new Config();
    }

    static Config instance() {
        return Holder.INSTANCE;
    }

    void setValue(String value) {
        this.value = value;
    }

    String value() {
        return value;
    }
}
