"""Structured and file logging configuration for the backend."""

import os
import sys
import logging
from logging.handlers import RotatingFileHandler

# Ensure logs directory exists
LOGS_DIR = "logs"
os.makedirs(LOGS_DIR, exist_ok=True)
LOG_FILE_PATH = os.path.join(LOGS_DIR, "app.log")

# Setup Formatter
LOG_FORMAT = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
formatter = logging.Formatter(LOG_FORMAT)

# Root Logger
root_logger = logging.getLogger()
root_logger.setLevel(logging.INFO)

# Console Handler
console_handler = logging.StreamHandler(sys.stdout)
console_handler.setFormatter(formatter)
console_handler.setLevel(logging.INFO)
root_logger.addHandler(console_handler)

# File Handler (Max 10MB per file, keep 5 backups)
file_handler = RotatingFileHandler(
    LOG_FILE_PATH,
    maxBytes=10 * 1024 * 1024,
    backupCount=5,
    encoding="utf-8"
)
file_handler.setFormatter(formatter)
file_handler.setLevel(logging.INFO)
root_logger.addHandler(file_handler)

# Prevent duplicate logs
logging.getLogger("uvicorn").propagate = False
logging.getLogger("fastapi").propagate = False


def get_logger(name: str) -> logging.Logger:
    """Return a logger instance for a given module name."""
    return logging.getLogger(name)
