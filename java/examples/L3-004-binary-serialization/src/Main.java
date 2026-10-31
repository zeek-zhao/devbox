import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;

public class Main {
    private static final int MAGIC = 0x44564258;
    private static final int VERSION = 1;
    private static final int MAX_PAYLOAD = 64;

    public static void main(String[] args) throws Exception {
        byte[] payload = "index".getBytes(StandardCharsets.UTF_8);
        byte[] record = encode(MAGIC, VERSION, payload);
        if (!decode(record).equals("index")) {
            throw new IllegalStateException("record roundtrip failed");
        }
        System.out.println("roundtrip: true");

        ByteArrayOutputStream integerBytes = new ByteArrayOutputStream();
        try (DataOutputStream output = new DataOutputStream(integerBytes)) {
            output.writeInt(0x01020304);
        }
        byte[] integer = integerBytes.toByteArray();
        if (integer.length != 4
                || integer[0] != 1 || integer[1] != 2
                || integer[2] != 3 || integer[3] != 4) {
            throw new IllegalStateException("unexpected byte order");
        }
        System.out.println("big-endian: 01 02 03 04");

        int rejected = 0;
        rejected += rejects(encode(0, VERSION, payload)) ? 1 : 0;
        rejected += rejects(encode(MAGIC, 2, payload)) ? 1 : 0;
        rejected += rejects(header(MAGIC, VERSION, MAX_PAYLOAD + 1, payload)) ? 1 : 0;
        rejected += rejects(new byte[]{0x44, 0x56}) ? 1 : 0;
        if (rejected != 4) {
            throw new IllegalStateException("invalid records were accepted");
        }
        System.out.println("invalid-inputs-rejected: " + rejected);
    }

    private static byte[] encode(int magic, int version, byte[] payload) throws IOException {
        return header(magic, version, payload.length, payload);
    }

    private static byte[] header(int magic, int version, int length, byte[] payload)
            throws IOException {
        ByteArrayOutputStream bytes = new ByteArrayOutputStream();
        try (DataOutputStream output = new DataOutputStream(bytes)) {
            output.writeInt(magic);
            output.writeShort(version);
            output.writeInt(length);
            output.write(payload);
        }
        return bytes.toByteArray();
    }

    private static String decode(byte[] record) throws IOException {
        try (DataInputStream input = new DataInputStream(new ByteArrayInputStream(record))) {
            if (input.readInt() != MAGIC) {
                throw new IOException("invalid magic");
            }
            if (input.readUnsignedShort() != VERSION) {
                throw new IOException("unsupported version");
            }
            int length = input.readInt();
            if (length < 0 || length > MAX_PAYLOAD) {
                throw new IOException("invalid payload length");
            }
            byte[] payload = new byte[length];
            input.readFully(payload);
            if (input.read() != -1) {
                throw new IOException("trailing bytes");
            }
            return new String(payload, StandardCharsets.UTF_8);
        }
    }

    private static boolean rejects(byte[] record) throws IOException {
        try {
            decode(record);
            return false;
        } catch (IOException expected) {
            return true;
        }
    }
}
