package api;

/** Provides stable normalization for required labels. */
public final class TextPolicy {
    private TextPolicy() {}

    /**
     * Normalize a required label.
     *
     * @param label the label to normalize
     * @return the normalized label
     * @throws IllegalArgumentException if the label is null or blank
     */
    public static String normalize(String label) {
        if (label == null || label.isBlank()) {
            throw new IllegalArgumentException("label is required");
        }
        return label.trim().toLowerCase();
    }

    /**
     * Runs the fixed documentation example.
     *
     * @param args command-line arguments, which are ignored
     */
    public static void main(String[] args) {
        System.out.println("normalized=" + normalize("  API  "));
    }
}
