from abc import ABC, abstractmethod


class Pipeline(ABC):
    def run(self):
        print("prepare")
        print(f"execute: {self.step()}")
        print("validate")

    @abstractmethod
    def step(self):
        pass


class UppercasePipeline(Pipeline):
    def step(self):
        return "python".upper()


class ReversePipeline(Pipeline):
    def step(self):
        return "python"[::-1]


def main():
    pipelines: tuple[Pipeline, ...] = (
        UppercasePipeline(),
        ReversePipeline(),
    )
    for pipeline in pipelines:
        pipeline.run()


if __name__ == "__main__":
    main()
