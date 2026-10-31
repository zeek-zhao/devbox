public class Main {
    public static void main(String[] args) {
        String literalOne = "index";
        String literalTwo = "index";
        String created = new String("index");
        System.out.println("literal identity: " + (literalOne == literalTwo));
        System.out.println("created identity: " + (literalOne == created));
        System.out.println("interned identity: " + (literalOne == created.intern()));

        String original = "doc";
        String ignored = original.concat("-key");
        System.out.println("original after ignored concat: " + original);
        String changed = original.concat("-key");
        System.out.println("received concat result: " + changed);
    }
}
