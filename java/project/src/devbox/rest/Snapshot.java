package devbox.rest;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

/** Portable binary backup of an API snapshot; no Java object deserialization. */
public final class Snapshot {
    private static final int MAGIC = 0x01020304;
    private static final int MAX_ITEMS = 10000;
    private Snapshot() {}

    /**
     * Encodes the snapshot.
     * @param items sorted items
     * @return big-endian version-1 backup
     * @throws IOException invalid snapshot order or size
     */
    public static byte[] encode(List<Api.Item> items) throws IOException {
        if (items.size() > MAX_ITEMS) throw new IOException("too many items");
        ByteArrayOutputStream bytes = new ByteArrayOutputStream();
        try (DataOutputStream out = new DataOutputStream(bytes)) { // L3-004-binary-serialization
            out.writeInt(MAGIC);
            out.writeInt(1);
            out.writeInt(items.size());
            int previous = 0;
            for (Api.Item item : items) {
                if (item.id() <= previous) throw new IOException("ids must be increasing");
                previous = item.id();
                byte[] name = item.name().getBytes(StandardCharsets.UTF_8);
                out.writeInt(item.id());
                out.writeInt(name.length);
                out.write(name);
            }
        }
        return bytes.toByteArray();
    }

    /**
     * Decodes and validates the complete backup.
     * @param bytes complete backup
     * @return validated immutable snapshot
     * @throws IOException corrupt, truncated or unsupported input
     */
    public static List<Api.Item> decode(byte[] bytes) throws IOException {
        try (DataInputStream in = new DataInputStream(new ByteArrayInputStream(bytes))) {
            if (in.readInt() != MAGIC || in.readInt() != 1) throw new IOException("invalid snapshot header");
            int count = in.readInt();
            if (count < 0 || count > MAX_ITEMS) throw new IOException("invalid item count");
            List<Api.Item> items = new ArrayList<>();
            int previous = 0;
            for (int i = 0; i < count; i++) {
                int id = in.readInt();
                if (id <= previous) throw new IOException("ids must be increasing");
                previous = id;
                int size = in.readInt();
                if (size < 1 || size > 256) throw new IOException("invalid name length");
                byte[] name = new byte[size];
                in.readFully(name);
                String decoded = StandardCharsets.UTF_8.newDecoder().onMalformedInput(CodingErrorAction.REPORT)
                        .onUnmappableCharacter(CodingErrorAction.REPORT).decode(ByteBuffer.wrap(name)).toString();
                try {
                    items.add(new Api.Item(id, decoded));
                } catch (ValidationException e) {
                    throw new IOException("invalid snapshot name", e);
                }
            }
            if (in.read() != -1) throw new IOException("trailing snapshot data");
            return List.copyOf(items);
        }
    }
}
