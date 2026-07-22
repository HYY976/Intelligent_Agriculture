from flask import Flask
from app.config import config_map
from app.extensions import db, cors, socketio


def create_app(config_name='development'):
    app = Flask(__name__)
    app.config.from_object(config_map.get(config_name, config_map['default']))

    # 初始化扩展
    db.init_app(app)
    cors.init_app(app, resources={r"/api/*": {"origins": "*"}})
    socketio.init_app(app, cors_allowed_origins="*", async_mode='eventlet')

    # 注册全部 Blueprint（来自 controllers）
    from app.controllers import register_blueprints
    register_blueprints(app)

    # 注册 WebSocket 事件
    from app.sockets import register_socket_events
    register_socket_events(socketio)

    # 创建表（开发模式）
    with app.app_context():
        from app import models  # noqa: F401  注册所有模型
        db.create_all()

    return app
