#include <cstdint>
#include <iomanip>
#include <iostream>
#include <optional>
#include <string>
#include <vector>

namespace {

using Bytes = std::vector<std::uint8_t>;

void append_u16_le(Bytes& bytes, std::uint16_t value) {
  bytes.push_back(static_cast<std::uint8_t>(value & 0xffU));
  bytes.push_back(static_cast<std::uint8_t>((value >> 8U) & 0xffU));
}

std::uint16_t read_u16_le(const Bytes& bytes, std::size_t offset) {
  return static_cast<std::uint16_t>(bytes[offset]) |
         static_cast<std::uint16_t>(
             static_cast<std::uint16_t>(bytes[offset + 1]) << 8U);
}

std::uint16_t checksum(const Bytes& bytes, std::size_t begin,
                       std::size_t length) {
  std::uint32_t sum = 0;
  for (std::size_t index = begin; index < begin + length; ++index) {
    sum += bytes[index];
  }
  return static_cast<std::uint16_t>(sum);
}

Bytes encode(const std::string& value) {
  Bytes bytes{0x44, 0x56, 0x42, 0x58, 0x01};
  append_u16_le(bytes, static_cast<std::uint16_t>(value.size()));
  for (const unsigned char character : value) {
    bytes.push_back(character);
  }
  append_u16_le(bytes, checksum(bytes, 7, value.size()));
  return bytes;
}

std::optional<std::string> decode(const Bytes& bytes) {
  constexpr std::size_t header_bytes = 7;
  constexpr std::size_t checksum_bytes = 2;
  if (bytes.size() < header_bytes + checksum_bytes ||
      bytes[0] != 0x44 || bytes[1] != 0x56 || bytes[2] != 0x42 ||
      bytes[3] != 0x58 || bytes[4] != 0x01) {
    return std::nullopt;
  }

  const std::size_t length = read_u16_le(bytes, 5);
  if (bytes.size() != header_bytes + length + checksum_bytes ||
      read_u16_le(bytes, header_bytes + length) !=
          checksum(bytes, header_bytes, length)) {
    return std::nullopt;
  }
  return std::string(bytes.begin() + static_cast<std::ptrdiff_t>(header_bytes),
                     bytes.begin() +
                         static_cast<std::ptrdiff_t>(header_bytes + length));
}

void print_bytes(const Bytes& bytes) {
  std::cout << "encoded:";
  for (const std::uint8_t byte : bytes) {
    std::cout << ' ' << std::setw(2) << std::setfill('0') << std::hex
              << static_cast<unsigned int>(byte);
  }
  std::cout << std::dec << std::setfill(' ') << '\n';
}

}  // namespace

int main() {
  const Bytes encoded = encode("cat");
  print_bytes(encoded);

  const auto decoded = decode(encoded);
  if (!decoded) {
    return 1;
  }
  std::cout << "decoded: " << *decoded << '\n';

  Bytes corrupted = encoded;
  corrupted[7] ^= 0x01U;
  std::cout << "corrupted: "
            << (decode(corrupted) ? "accepted" : "rejected") << '\n';
}
