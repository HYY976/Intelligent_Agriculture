from functools import wraps
from flask import request, g
from app.utils.response import error_response
from app.utils.jwt_util import verify_token


def jwt_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        auth_header = request.headers.get('Authorization', '')
        if not auth_header.startswith('Bearer '):
            return error_response(401, 'Missing or invalid Authorization header')
        token = auth_header.split(' ', 1)[1]
        try:
            payload = verify_token(token)
        except ValueError as e:
            return error_response(401, str(e))
        g.current_user = payload
        return f(*args, **kwargs)
    return decorated


def role_required(*roles):
    def decorator(f):
        @wraps(f)
        def decorated(*args, **kwargs):
            user = getattr(g, 'current_user', None)
            if user is None:
                return error_response(401, 'Authentication required')
            if user.get('role') not in roles and user.get('user_type') not in roles:
                return error_response(403, 'Insufficient permissions')
            return f(*args, **kwargs)
        return decorated
    return decorator
