import java.lang.reflect.Method;

public class Main {
    public static void main(String[] args) throws ReflectiveOperationException {
        Class<?> handlerType = Class.forName("OwnHandler");
        Method label = handlerType.getDeclaredMethod("label");
        Object handler = handlerType.getDeclaredConstructor().newInstance();

        try {
            label.invoke(handler);
        } catch (IllegalAccessException exception) {
            System.out.println("before-open=" + exception.getClass().getSimpleName());
        }
        label.setAccessible(true);
        System.out.println("after-open=" + label.invoke(handler));

        try {
            handlerType.getDeclaredMethod("missing");
        } catch (NoSuchMethodException exception) {
            System.out.println("missing=" + exception.getClass().getSimpleName());
        }
    }
}

final class OwnHandler {
    private String label() {
        return "handler-ready";
    }
}
