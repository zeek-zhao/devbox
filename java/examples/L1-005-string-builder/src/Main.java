public class Main {
    public static void main(String[] args) {
        String plusResult = "";
        StringBuilder builder = new StringBuilder();
        for (int i = 0; i < 4; i++) {
            String part = "t" + i;
            plusResult = plusResult + part;
            builder.append(part);
        }

        String snapshot = builder.toString();
        StringBuilder alias = builder;
        alias.append("-done");
        System.out.println("plus result: " + plusResult);
        System.out.println("builder snapshot: " + snapshot);
        System.out.println("builder alias result: " + builder);
    }
}
