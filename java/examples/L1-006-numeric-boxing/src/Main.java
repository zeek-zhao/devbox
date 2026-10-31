public class Main {
    public static void main(String[] args) {
        System.out.println("integer division: " + (5 / 2));
        System.out.println("narrowed byte: " + (byte) 130);

        try {
            Math.addExact(Integer.MAX_VALUE, 1);
            System.out.println("overflow detected: false");
        } catch (ArithmeticException expected) {
            System.out.println("overflow detected: true");
        }

        Integer boxed = null;
        if (boxed == null) {
            System.out.println("null wrapper checked: true");
        } else {
            int value = boxed;
            System.out.println("unboxed value: " + value);
        }
    }
}
