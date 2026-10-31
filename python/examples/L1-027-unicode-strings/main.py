text = "é🙂"
encoded = text.encode("utf-8")
print("code point count:", len(text))
print("UTF-8 byte count:", len(encoded))
print("second character:", text[1])
