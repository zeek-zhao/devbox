fn encode(version: u8, value: u32) -> [u8; 5] {
    let encoded = value.to_le_bytes();
    [version, encoded[0], encoded[1], encoded[2], encoded[3]]
}

fn decode(bytes: &[u8]) -> Result<(u8, u32), &'static str> {
    if bytes.len() != 5 {
        return Err("invalid length");
    }
    if bytes[0] != 1 {
        return Err("unsupported version");
    }
    let value = u32::from_le_bytes([bytes[1], bytes[2], bytes[3], bytes[4]]);
    if value > 1000 {
        return Err("value out of range");
    }
    Ok((bytes[0], value))
}

fn main() {
    let encoded = encode(1, 513);
    let bytes = encoded
        .iter()
        .map(|byte| format!("{byte:02x}"))
        .collect::<Vec<_>>()
        .join(" ");
    let (version, value) = decode(&encoded).expect("encoded record is valid");

    println!("bytes: {bytes}");
    println!("decoded: version={version}, value={value}");
    println!("truncated rejected: {}", decode(&encoded[..4]).is_err());
}
