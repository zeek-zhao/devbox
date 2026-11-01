package devbox.rest;

import java.util.List;
import java.util.Objects;
import java.util.regex.Pattern;

/** Deliberately small JSON schema: exactly one string field named "name". */
public final class Json {
    private static final Pattern NAME =
            Pattern.compile(
                    "[\\p{L}\\p{N}][\\p{L}\\p{N} _.'\"\\\\-]{0,63}"); // L1-008-class-initialization

    private Json() {}

    /**
     * Validates the name schema.
     *
     * @param name input name
     * @return validated name
     * @throws ValidationException invalid name
     */
    public static String validateName(String name) {
        if (name == null || !NAME.matcher(name).matches()) {
            throw new ValidationException("name must be 1..64 letters, digits or safe punctuation");
        }
        validUnicode(name);
        return name;
    }

    /**
     * Serializes a create/update request.
     *
     * @param name a string
     * @return one-field JSON object
     */
    public static String name(String name) {
        return "{\"name\":" + quote(name) + "}";
    }

    /**
     * Serializes an item.
     *
     * @param item stored item
     * @return JSON object
     */
    public static String item(Api.Item item) {
        return "{\"id\":" + item.id() + ",\"name\":" + quote(item.name()) + "}";
    }

    /**
     * Serializes a snapshot.
     *
     * @param items sorted snapshot
     * @return JSON array
     */
    public static String items(List<Api.Item> items) {
        return items.stream()
                .map(Json::item)
                .collect(java.util.stream.Collectors.joining(",", "[", "]"));
    }

    /**
     * Escapes JSON string syntax and controls.
     *
     * @param value string
     * @return escaped JSON string
     */
    public static String quote(String value) {
        Objects.requireNonNull(value, "value");
        validUnicode(value);
        StringBuilder out = new StringBuilder("\""); // L1-005-string-builder
        for (int i = 0; i < value.length(); i++) {
            char c = value.charAt(i);
            switch (c) {
                case '"' -> out.append("\\\"");
                case '\\' -> out.append("\\\\");
                case '\n' -> out.append("\\n");
                case '\r' -> out.append("\\r");
                case '\t' -> out.append("\\t");
                case '\b' -> out.append("\\b");
                case '\f' -> out.append("\\f");
                default -> {
                    if (c < 0x20) {
                        out.append("\\u");
                        for (int shift = 12; shift >= 0; shift -= 4) {
                            out.append(Character.forDigit((c >> shift) & 15, 16));
                        }
                    } else out.append(c);
                }
            }
        }
        return out.append('"').toString();
    }

    /**
     * Parses the complete single-field request.
     *
     * @param input complete JSON document
     * @return validated name
     * @throws ValidationException bad schema
     */
    public static String parseName(String input) {
        Cursor cursor = new Cursor(input);
        cursor.expect('{');
        if (!"name".equals(cursor.string())) throw new ValidationException("expected name field");
        cursor.expect(':');
        String name = cursor.string();
        cursor.expect('}');
        cursor.space();
        if (cursor.position != input.length()) throw new ValidationException("trailing JSON");
        return validateName(name);
    }

    private static void validUnicode(String value) {
        for (int i = 0; i < value.length(); i++) {
            char c = value.charAt(i);
            if (Character.isHighSurrogate(c)) {
                if (++i == value.length() || !Character.isLowSurrogate(value.charAt(i))) {
                    throw new ValidationException("unpaired surrogate");
                }
            } else if (Character.isLowSurrogate(c))
                throw new ValidationException("unpaired surrogate");
        }
    }

    private static final class Cursor {
        private final String input;
        private int position;

        Cursor(String input) {
            this.input = Objects.requireNonNull(input, "input");
        }

        void space() {
            while (position < input.length() && " \t\r\n".indexOf(input.charAt(position)) >= 0)
                position++;
        }

        void expect(char wanted) {
            space();
            if (position == input.length() || input.charAt(position++) != wanted) {
                throw new ValidationException("expected " + wanted);
            }
        }

        String string() {
            expect('"');
            StringBuilder out = new StringBuilder();
            while (position < input.length()) {
                char c = input.charAt(position++);
                if (c == '"') {
                    String result = out.toString();
                    validUnicode(result);
                    return result;
                }
                if (c < 0x20) throw new ValidationException("unescaped control character");
                if (c != '\\') {
                    out.append(c);
                    continue;
                }
                if (position == input.length()) throw new ValidationException("truncated escape");
                char escaped = input.charAt(position++);
                switch (escaped) {
                    case '"', '\\', '/' -> out.append(escaped);
                    case 'b' -> out.append('\b');
                    case 'f' -> out.append('\f');
                    case 'n' -> out.append('\n');
                    case 'r' -> out.append('\r');
                    case 't' -> out.append('\t');
                    case 'u' -> {
                        if (input.length() - position < 4)
                            throw new ValidationException("truncated unicode");
                        int code = 0;
                        for (int j = 0; j < 4; j++) {
                            char digit = input.charAt(position++);
                            int number = digit <= 127 ? Character.digit(digit, 16) : -1;
                            if (number < 0) throw new ValidationException("invalid unicode escape");
                            code = (code << 4) | number;
                        }
                        out.append((char) code);
                    }
                    default -> throw new ValidationException("invalid escape");
                }
            }
            throw new ValidationException("unterminated string");
        }
    }
}
