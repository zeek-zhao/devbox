package devbox.tests;

/** Test-only native interoperability check for snapshot identifiers. */
public final class NativeChecksum {
    static { System.loadLibrary("snapshot"); } // L3-006-jni-native
    private NativeChecksum() {}

    /**
     * Sums snapshot identifiers without narrowing the result.
     * @param ids snapshot identifiers
     * @return 64-bit checksum
     */
    public static native long sum(int[] ids);

    /**
     * Also serves as the missing-library subprocess probe.
     * @param args unused
     */
    public static void main(String[] args) {
        if (sum(new int[]{2, 3}) != 5) throw new AssertionError("native checksum mismatch");
    }
}
