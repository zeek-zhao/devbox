public class Main {
    interface Button {
        String family();
    }

    interface Checkbox {
        String family();
    }

    record LightButton() implements Button {
        @Override
        public String family() {
            return "light";
        }
    }

    record LightCheckbox() implements Checkbox {
        @Override
        public String family() {
            return "light";
        }
    }

    record DarkButton() implements Button {
        @Override
        public String family() {
            return "dark";
        }
    }

    record DarkCheckbox() implements Checkbox {
        @Override
        public String family() {
            return "dark";
        }
    }

    interface AbstractFactory<B extends Button, C extends Checkbox> {
        B createButton();

        C createCheckbox();
    }

    static final class LightFactory implements AbstractFactory<LightButton, LightCheckbox> {
        @Override
        public LightButton createButton() {
            return new LightButton();
        }

        @Override
        public LightCheckbox createCheckbox() {
            return new LightCheckbox();
        }
    }

    static final class DarkFactory implements AbstractFactory<DarkButton, DarkCheckbox> {
        @Override
        public DarkButton createButton() {
            return new DarkButton();
        }

        @Override
        public DarkCheckbox createCheckbox() {
            return new DarkCheckbox();
        }
    }

    private static String inspect(AbstractFactory<? extends Button, ? extends Checkbox> factory) {
        Button button = factory.createButton();
        Checkbox checkbox = factory.createCheckbox();
        System.out.println("family: " + button.family() + "/" + checkbox.family());
        System.out.println("paired: " + button.family().equals(checkbox.family()));
        return button.family();
    }

    public static void main(String[] args) {
        String light = inspect(new LightFactory());
        String dark = inspect(new DarkFactory());
        System.out.println("different families: " + !light.equals(dark));
    }
}
