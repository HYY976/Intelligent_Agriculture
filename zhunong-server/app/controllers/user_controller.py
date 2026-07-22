"""
user_controller - 用户端核心 API
  - POST /login     手机号+验证码登录（任意6位码通过）
  - POST /sms_code  发送验证码（Mock）
  - POST /register  手机号注册
  - GET  /profile   获取当前用户信息（需 JWT）
  - PUT  /profile   更新用户昵称/头像
"""

import time
from flask import Blueprint, jsonify, request, g
from werkzeug.security import generate_password_hash, check_password_hash
from app.extensions import db
from app.models.user import User, FarmerProfile
from app.utils.response import success_response, error_response
from app.utils.jwt_util import generate_user_token
from app.utils.decorators import jwt_required

user_bp = Blueprint('user', __name__, url_prefix='/api/user')


@user_bp.route('/health', methods=['GET'])
def health():
    return jsonify({'code': 200, 'msg': 'ok', 'data': {'service': 'user'}})


# ==================== 验证码 ====================

@user_bp.route('/sms_code', methods=['POST'])
def send_sms_code():
    """
    发送验证码（Mock：直接返回成功，任意6位数字均可通过）
    POST /api/user/sms_code
    body: { phone }
    """
    body = request.get_json(silent=True) or {}
    phone = body.get('phone', '')
    if not phone or len(phone) != 11:
        return error_response(400, '手机号格式不正确')
    return success_response(None, msg='验证码已发送')


# ==================== 登录 ====================

@user_bp.route('/login', methods=['POST'])
def login():
    """
    账号+密码登录
    POST /api/user/login
    body: { phone, password, userType: 'user' }
    return: { token, userInfo }
    """
    body = request.get_json(silent=True) or {}
    phone = body.get('phone', '')
    password = body.get('password', '')
    user_type = body.get('userType', 'user')

    if not phone or len(phone) != 11:
        return error_response(400, '手机号格式不正确')
    if not password or len(password) < 6:
        return error_response(400, '密码至少6位')

    # 查找用户并校验密码
    user = User.query.filter_by(phone=phone).first()
    if user is None or not check_password_hash(user.password_hash, password):
        return error_response(401, '账号或密码错误')

    # 检查封禁状态
    if user.status == 'banned':
        return error_response(403, '账号已被封禁')

    # 更新登录时间
    user.last_login_at = int(time.time() * 1000)
    db.session.commit()

    # 生成 JWT
    token = generate_user_token(user.id, user.user_type)

    # 构造 userInfo（对齐前端 UserInfo 接口）
    user_info = {
        'userId': user.id,
        'phone': user.phone,
        'nickname': user.nickname or '',
        'avatar': user.avatar or '',
        'userType': user.user_type,
        'status': user.status,
        'createdAt': user.created_at,
        'lastLoginAt': user.last_login_at,
    }

    return success_response({'token': token, 'userInfo': user_info})


# ==================== 注册 ====================

@user_bp.route('/register', methods=['POST'])
def register():
    """
    账号+密码注册
    POST /api/user/register
    body: { phone, password, nickname?, userType? }
    return: { token, userInfo }
    """
    body = request.get_json(silent=True) or {}
    phone = body.get('phone', '')
    password = body.get('password', '')
    nickname = body.get('nickname', '')
    user_type = body.get('userType', 'user')

    if not phone or len(phone) != 11:
        return error_response(400, '手机号格式不正确')
    if not password or len(password) < 6:
        return error_response(400, '密码至少6位')

    existing = User.query.filter_by(phone=phone).first()
    if existing:
        return error_response(409, '该手机号已注册')

    user = User(
        phone=phone,
        nickname=nickname or f'用户{phone[-4:]}',
        password_hash=generate_password_hash(password),
        user_type=user_type,
    )
    db.session.add(user)
    db.session.commit()

    token = generate_user_token(user.id, user.user_type)
    user_info = {
        'userId': user.id,
        'phone': user.phone,
        'nickname': user.nickname or '',
        'avatar': user.avatar or '',
        'userType': user.user_type,
        'status': user.status,
        'createdAt': user.created_at,
        'lastLoginAt': user.last_login_at or 0,
    }

    return success_response({'token': token, 'userInfo': user_info})


# ==================== 个人信息 ====================

@user_bp.route('/profile', methods=['GET'])
@jwt_required
def get_profile():
    """
    获取当前用户信息
    GET /api/user/profile
    """
    payload = g.current_user
    user_id = payload.get('user_id')
    user = User.query.get(user_id)
    if not user:
        return error_response(404, '用户不存在')

    user_info = {
        'userId': user.id,
        'phone': user.phone,
        'nickname': user.nickname or '',
        'avatar': user.avatar or '',
        'userType': user.user_type,
        'status': user.status,
        'createdAt': user.created_at,
        'lastLoginAt': user.last_login_at or 0,
    }

    # 如果是农户，附加农户信息
    if user.user_type == 'farmer':
        fp = FarmerProfile.query.filter_by(user_id=user.id).first()
        if fp:
            user_info['farmerProfile'] = {
                'shopName': fp.shop_name or '',
                'shopLogo': fp.shop_logo or '',
                'shopIntro': fp.shop_intro or '',
                'certificationStatus': fp.certification_status,
                'totalRevenue': float(fp.total_revenue or 0),
                'availableBalance': float(fp.available_balance or 0),
                'fansCount': fp.fans_count,
            }

    return success_response(user_info)


@user_bp.route('/profile', methods=['PUT'])
@jwt_required
def update_profile():
    """
    更新用户昵称/头像
    PUT /api/user/profile
    body: { nickname?, avatar? }
    """
    payload = g.current_user
    user_id = payload.get('user_id')
    user = User.query.get(user_id)
    if not user:
        return error_response(404, '用户不存在')

    body = request.get_json(silent=True) or {}
    if 'nickname' in body and body['nickname']:
        user.nickname = body['nickname']
    if 'avatar' in body and body['avatar']:
        user.avatar = body['avatar']

    db.session.commit()

    return success_response({
        'userId': user.id,
        'nickname': user.nickname or '',
        'avatar': user.avatar or '',
    })
