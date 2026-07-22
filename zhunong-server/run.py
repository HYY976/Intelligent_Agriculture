import sys
import os
from app import create_app, socketio
from app.config import config_map

config_name = os.getenv('FLASK_ENV', 'development')
app = create_app(config_name)


@app.cli.command('init-db')
def init_db():
    """初始化数据库表"""
    from app.extensions import db
    db.create_all()
    print('Database tables created.')


@app.cli.command('seed')
def seed():
    """填充种子数据"""
    from seed.seed_data import run_seed
    run_seed()
    print('Seed data inserted.')


if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] in ('init-db', 'seed'):
        # 支持 `python run.py init-db` / `python run.py seed` 调用 Flask CLI 命令
        app.cli.main()
    else:
        socketio.run(app, host='0.0.0.0', port=5000, debug=app.config.get('DEBUG', False))
