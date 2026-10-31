import ctypes


def main() -> None:
    libc = ctypes.CDLL(None)
    strlen = libc.strlen
    strlen.argtypes = [ctypes.c_char_p]
    strlen.restype = ctypes.c_size_t

    value = b"devbox"
    print(f"input bytes: {len(value)}")
    print(f"libc strlen: {strlen(value)}")


if __name__ == "__main__":
    main()
