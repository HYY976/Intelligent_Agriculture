import os
from datetime import timedelta


class BaseConfig:
    SECRET_KEY = os.getenv('SECRET_KEY', 'zhunong-dev-secret')
    JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'zhunong-dev-secret')
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(days=7)
    ADMIN_TOKEN_EXPIRES = timedelta(hours=24)
    UPLOAD_FOLDER = 'app/static/uploads'
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024
    SQLALCHEMY_TRACK_MODIFICATIONS = False


class DevConfig(BaseConfig):
    """开发环境：SQLite 零配置启动（比赛演示用，赛后可切回 MySQL）"""
    SQLALCHEMY_DATABASE_URI = 'sqlite:///zhunong.db'
    CHROMA_PERSIST_DIR = './chroma_data'
    DEBUG = True


class ProdConfig(BaseConfig):
    SQLALCHEMY_DATABASE_URI = os.getenv(
        'DB_URI',
        'mysql+pymysql://zhunong:zhunong123@127.0.0.1:3306/zhunong?charset=utf8mb4',
    )
    CHROMA_PERSIST_DIR = os.getenv('CHROMA_PERSIST_DIR', '/app/chroma_data')
    DEBUG = False


config_map = {
    'development': DevConfig,
    'production': ProdConfig,
    'default': DevConfig,
}
