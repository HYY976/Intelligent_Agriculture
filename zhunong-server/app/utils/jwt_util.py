import jwt
from datetime import datetime, timedelta, timezone
from flask import current_app


def generate_user_token(user_id, user_type):
    """生成用户/卖家 Token，有效期 7 天"""
    expire = timedelta(days=7)
    payload = {
        'user_id': user_id,
        'user_type': user_type,
        'type': 'user',
        'exp': datetime.now(timezone.utc) + expire,
        'iat': datetime.now(timezone.utc),
    }
    secret = current_app.config.get('JWT_SECRET_KEY')
    return jwt.encode(payload, secret, algorithm='HS256')


def generate_admin_token(admin_id, role):
    """生成管理员 Token，有效期 24 小时"""
    expire = timedelta(hours=24)
    payload = {
        'admin_id': admin_id,
        'role': role,
        'type': 'admin',
        'exp': datetime.now(timezone.utc) + expire,
        'iat': datetime.now(timezone.utc),
    }
    secret = current_app.config.get('JWT_SECRET_KEY')
    return jwt.encode(payload, secret, algorithm='HS256')


def verify_token(token):
    """校验并解析 Token，返回 payload 或抛出 ValueError"""
    secret = current_app.config.get('JWT_SECRET_KEY')
    try:
        payload = jwt.decode(token, secret, algorithms=['HS256'])
        return payload
    except jwt.ExpiredSignatureError:
        raise ValueError('Token expired')
    except jwt.InvalidTokenError:
        raise ValueError('Invalid token')
