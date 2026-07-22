import logging
import os
from logging.handlers import RotatingFileHandler


def get_logger(name='zhunong'):
    """获取按场景分级的日志器"""
    logger = logging.getLogger(name)
    if logger.handlers:
        return logger
    logger.setLevel(logging.INFO)
    formatter = logging.Formatter(
        '[%(asctime)s] %(levelname)s in %(name)s: %(message)s'
    )

    console = logging.StreamHandler()
    console.setFormatter(formatter)
    logger.addHandler(console)

    log_dir = os.getenv('LOG_DIR', 'logs')
    try:
        os.makedirs(log_dir, exist_ok=True)
        file_handler = RotatingFileHandler(
            os.path.join(log_dir, '%s.log' % name),
            maxBytes=10 * 1024 * 1024,
            backupCount=5,
            encoding='utf-8',
        )
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)
    except OSError:
        pass

    return logger
