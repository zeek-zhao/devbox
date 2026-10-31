import logging
import sys


handler = logging.StreamHandler(sys.stdout)
handler.setFormatter(logging.Formatter("%(levelname)s:%(name)s:%(message)s"))
logging.basicConfig(level=logging.WARNING, handlers=[handler], force=True)

logger = logging.getLogger("report")
logger.info("starting")
logger.warning("input skipped")
