"""E-010 结构化错误日志：一行一条 JSON，错误类别是可检索字段而非消息前缀。"""

import json
import logging
import sys


class JsonFormatter(logging.Formatter):
    def format(self, record):
        payload = {
            "code": getattr(record, "code", "INTERNAL"),
            "level": record.levelname,
            "message": record.getMessage(),
        }
        return json.dumps(payload, sort_keys=True)


def build_logger():
    logger = logging.getLogger("app")
    logger.setLevel(logging.INFO)
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JsonFormatter())
    logger.handlers = [handler]
    logger.propagate = False
    return logger


def main():
    logger = build_logger()
    logger.error("database unavailable", extra={"code": "TRANSIENT"})
    logger.error("field age must be a positive integer", extra={"code": "VALIDATION"})
    logger.info("handled 2 errors, service up", extra={"code": "NONE"})


if __name__ == "__main__":
    main()
