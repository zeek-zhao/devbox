import struct


def main() -> None:
    format_string = ">Ih"
    packed = struct.pack(format_string, 513, -12)
    unpacked = struct.unpack(format_string, packed)
    print(f"bytes: {packed.hex()}")
    print(f"format length: {struct.calcsize(format_string)}")
    print(f"round trip: {unpacked == (513, -12)}")


if __name__ == "__main__":
    main()
