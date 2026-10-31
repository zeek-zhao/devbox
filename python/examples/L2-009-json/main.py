import json


def main() -> None:
    payload = {"name": "Ada", "roles": ["reader", "writer"], "active": True}
    encoded = json.dumps(payload, sort_keys=True, separators=(",", ":"))
    decoded = json.loads(encoded)

    print(f"encoded: {encoded}")
    print(f"round trip: {decoded == payload}")
    print(f"object key order is semantic: {json.loads('{\"b\":2,\"a\":1}') != json.loads('{\"a\":1,\"b\":2}')}")


if __name__ == "__main__":
    main()
