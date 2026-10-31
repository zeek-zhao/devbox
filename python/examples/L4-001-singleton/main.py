class Config:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance.mode = "default"
        return cls._instance


def main():
    first = Config()
    first.mode = "offline"
    second = Config()
    print("same instance:", first is second)
    print("second sees:", second.mode)
    print("two constructions:", Config() is Config())
    assert first is second
    assert second.mode == "offline"


if __name__ == "__main__":
    main()
