public class Main {
    public static void main(String[] args) {
        String[] words = {"index", "term"};
        System.out.println("array length: " + words.length);

        boolean boundsChecked = false;
        try {
            String ignored = words[words.length];
        } catch (ArrayIndexOutOfBoundsException expected) {
            boundsChecked = true;
        }
        System.out.println("out of bounds detected: " + boundsChecked);

        Object[] covariant = words;
        boolean storeChecked = false;
        try {
            covariant[0] = Integer.valueOf(7);
        } catch (ArrayStoreException expected) {
            storeChecked = true;
        }
        System.out.println("covariant store rejected: " + storeChecked);
        System.out.println("original element: " + words[0]);
    }
}
