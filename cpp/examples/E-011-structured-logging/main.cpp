#include <iostream>
#include <string>

// 日志与可观测：结构化日志行 = 级别 + 序号 + 事件 + 上下文键值。
// 演练里用自增序号替代时间戳（时间会让输出不确定）；真实项目换成
// 毫秒时间戳后，格式与分级策略不变。

enum class Level { Info, Warn, Error };

static const char* level_name(Level l) {
    switch (l) {
    case Level::Info:
        return "INFO";
    case Level::Warn:
        return "WARN";
    case Level::Error:
        return "ERROR";
    }
    return "???";
}

class Logger {
public:
    explicit Logger(int seq_start) : next_(seq_start) {}

    void log(Level l, const std::string& event, const std::string& kv) {
        // 一行一条，字段位置固定：grep 级别、awk 取字段都稳定。
        std::cout << level_name(l) << " #" << next_ << " event=" << event;
        if (!kv.empty()) {
            std::cout << ' ' << kv;
        }
        std::cout << '\n';
        ++next_;
    }

private:
    int next_;
};

int main() {
    Logger logger(1);

    logger.log(Level::Info, "startup", "pid=static");
    logger.log(Level::Info, "index_load", "docs=100 terms=42");
    logger.log(Level::Warn, "slow_query", "ms=950 query=join");
    logger.log(Level::Error, "index_corrupt", "offset=16 code=3");
    logger.log(Level::Info, "shutdown", "clean=true");

    // 观测用途：错误行必须自含上下文，日志聚合后单行即可定位。
    return 0;
}
