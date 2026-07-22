"""
admin_controller - 管理后台 API
  - POST /login          管理员用户名+密码登录
  - GET  /dashboard/stats 控制台统计数据
  - GET  /users          用户列表（多条件搜索分页）
  - GET  /users/<id>     用户详情聚合
  - PUT  /users/<id>/ban   封禁用户
  - PUT  /users/<id>/unban 解封用户
  - PUT  /users/<id>/reset-password 重置密码
  - GET  /reviews        审核列表
  - GET  /reviews/<id>   审核详情
  - PUT  /reviews/<id>/approve 审核通过
  - PUT  /reviews/<id>/reject  审核驳回
  - GET  /reviews/pending-count 待审核数量
  - GET  /apis           API 列表
  - GET  /apis/<id>      API 详情
  - GET  /api-keys       密钥列表
  - POST /api-keys       创建密钥
  - PUT  /api-keys/<id>/revoke 吊销密钥
"""

import time
import uuid
import secrets
from flask import Blueprint, jsonify, request, g
from werkzeug.security import generate_password_hash, check_password_hash
from app.extensions import db
from app.models.user import User, FarmerProfile, Admin
from app.models.review import ContentReview, Report
from app.models.admin_ext import ApiInfo, ApiKey, RateLimitConfig
from app.utils.response import success_response, error_response
from app.utils.jwt_util import generate_admin_token
from app.utils.decorators import jwt_required, role_required

admin_bp = Blueprint('admin', __name__, url_prefix='/api/admin')


@admin_bp.route('/health', methods=['GET'])
def health():
    return jsonify({'code': 200, 'msg': 'ok', 'data': {'service': 'admin'}})


# ==================== 登录 ====================

@admin_bp.route('/login', methods=['POST'])
def login():
    """
    管理员登录
    POST /api/admin/login
    body: { username, password }
    return: { token, adminInfo }
    """
    body = request.get_json(silent=True) or {}
    username = body.get('username', '')
    password = body.get('password', '')

    if not username or not password:
        return error_response(400, '用户名和密码不能为空')

    admin = Admin.query.filter_by(username=username).first()
    if not admin or not check_password_hash(admin.password_hash, password):
        return error_response(401, '用户名或密码错误')

    # 更新登录时间
    admin.last_login_at = int(time.time() * 1000)
    db.session.commit()

    # 生成 JWT
    token = generate_admin_token(admin.id, admin.role)

    # 构造 adminInfo（对齐前端 AdminInfo 接口）
    admin_info = {
        'adminId': admin.id,
        'username': admin.username,
        'nickname': admin.nickname or admin.username,
        'role': admin.role,
        'lastLoginAt': admin.last_login_at,
    }

    return success_response({'token': token, 'adminInfo': admin_info})


# ==================== 控制台统计 ====================

@admin_bp.route('/dashboard/stats', methods=['GET'])
@jwt_required
def dashboard_stats():
    """
    控制台统计数据
    GET /api/admin/dashboard/stats
    """
    total_users = User.query.filter_by(user_type='user').count()
    total_farmers = User.query.filter_by(user_type='farmer').count()
    pending_reviews = ContentReview.query.filter_by(status='pending').count()
    # 近24小时订单数（简化：返回全部订单数）
    from app.models.order import Order
    today_orders = Order.query.count()

    return success_response({
        'totalUsers': total_users,
        'totalFarmers': total_farmers,
        'pendingReviews': pending_reviews,
        'todayOrders': today_orders,
    })


# ==================== 用户管理 ====================

@admin_bp.route('/users', methods=['GET'])
@jwt_required
def user_list():
    """
    用户列表（多条件搜索分页）
    GET /api/admin/users?page=1&size=20&keyword=&phone=&userType=&status=
    """
    page = int(request.args.get('page', 1))
    size = int(request.args.get('size', 20))
    keyword = request.args.get('keyword', '')
    phone = request.args.get('phone', '')
    user_type = request.args.get('userType', '')
    status = request.args.get('status', '')

    query = User.query
    if keyword:
        query = query.filter(User.nickname.contains(keyword))
    if phone:
        query = query.filter(User.phone.contains(phone))
    if user_type:
        query = query.filter_by(user_type=user_type)
    if status:
        query = query.filter_by(status=status)

    total = query.count()
    users = query.order_by(User.created_at.desc()).offset((page - 1) * size).limit(size).all()

    items = []
    for u in users:
        item = {
            'userId': u.id,
            'phone': u.phone,
            'nickname': u.nickname or '',
            'avatar': u.avatar or '',
            'userType': u.user_type,
            'status': u.status,
            'createdAt': u.created_at,
            'lastLoginAt': u.last_login_at or 0,
        }
        if u.user_type == 'farmer':
            fp = FarmerProfile.query.filter_by(user_id=u.id).first()
            if fp:
                item['shopName'] = fp.shop_name or ''
                item['certificationStatus'] = fp.certification_status
        items.append(item)

    return success_response({
        'list': items,
        'total': total,
        'page': page,
        'size': size,
        'hasMore': (page * size) < total,
    })


@admin_bp.route('/users/<user_id>', methods=['GET'])
@jwt_required
def user_detail(user_id):
    """
    用户详情聚合
    GET /api/admin/users/<user_id>
    """
    user = User.query.get(user_id)
    if not user:
        return error_response(404, '用户不存在')

    result = {
        'userId': user.id,
        'phone': user.phone,
        'nickname': user.nickname or '',
        'avatar': user.avatar or '',
        'userType': user.user_type,
        'status': user.status,
        'banReason': user.ban_reason or '',
        'createdAt': user.created_at,
        'lastLoginAt': user.last_login_at or 0,
        'lastLoginIp': user.last_login_ip or '',
    }

    if user.user_type == 'farmer':
        fp = FarmerProfile.query.filter_by(user_id=user.id).first()
        if fp:
            result['farmerProfile'] = {
                'shopName': fp.shop_name or '',
                'shopIntro': fp.shop_intro or '',
                'certificationStatus': fp.certification_status,
                'totalRevenue': float(fp.total_revenue or 0),
                'availableBalance': float(fp.available_balance or 0),
                'fansCount': fp.fans_count,
            }

    # 订单统计
    from app.models.order import Order
    order_count = Order.query.filter_by(buyer_id=user.id).count()
    result['orderCount'] = order_count

    return success_response(result)


@admin_bp.route('/users/<user_id>/ban', methods=['PUT'])
@jwt_required
def ban_user(user_id):
    """
    封禁用户
    PUT /api/admin/users/<user_id>/ban
    body: { reason, duration? }
    """
    user = User.query.get(user_id)
    if not user:
        return error_response(404, '用户不存在')

    body = request.get_json(silent=True) or {}
    reason = body.get('reason', '管理员封禁')
    user.status = 'banned'
    user.ban_reason = reason
    db.session.commit()

    return success_response({'userId': user.id, 'status': 'banned', 'reason': reason})


@admin_bp.route('/users/<user_id>/unban', methods=['PUT'])
@jwt_required
def unban_user(user_id):
    """
    解封用户
    PUT /api/admin/users/<user_id>/unban
    """
    user = User.query.get(user_id)
    if not user:
        return error_response(404, '用户不存在')

    user.status = 'active'
    user.ban_reason = None
    db.session.commit()

    return success_response({'userId': user.id, 'status': 'active'})


@admin_bp.route('/users/<user_id>/reset-password', methods=['PUT'])
@jwt_required
def reset_password(user_id):
    """
    重置用户密码
    PUT /api/admin/users/<user_id>/reset-password
    """
    user = User.query.get(user_id)
    if not user:
        return error_response(404, '用户不存在')

    user.password_hash = generate_password_hash('123456')
    db.session.commit()

    return success_response({'userId': user.id, 'msg': '密码已重置为默认值'})


# ==================== 内容审核 ====================

@admin_bp.route('/reviews', methods=['GET'])
@jwt_required
def review_list():
    """
    审核列表
    GET /api/admin/reviews?page=1&size=20&contentType=&status=
    """
    page = int(request.args.get('page', 1))
    size = int(request.args.get('size', 20))
    content_type = request.args.get('contentType', '')
    status = request.args.get('status', '')

    query = ContentReview.query
    if content_type:
        query = query.filter_by(content_type=content_type)
    if status:
        query = query.filter_by(status=status)

    total = query.count()
    reviews = query.order_by(ContentReview.created_at.desc()).offset((page - 1) * size).limit(size).all()

    items = []
    for r in reviews:
        # 获取提交者信息
        submitter = User.query.get(r.submitter_id)
        item = {
            'reviewId': r.id,
            'contentType': r.content_type,
            'contentId': r.content_id,
            'submitterId': r.submitter_id,
            'submitterName': submitter.nickname if submitter else '',
            'status': r.status,
            'rejectReason': r.reject_reason or '',
            'createdAt': r.created_at,
            'reviewedAt': r.reviewed_at or 0,
        }
        # 附加内容摘要
        if r.content_type == 'product':
            from app.models.product import Product
            prod = Product.query.get(r.content_id)
            if prod:
                item['contentTitle'] = prod.title
                item['contentImage'] = (prod.main_images or [''])[0] if prod.main_images else ''
        elif r.content_type == 'post':
            from app.models.community import Post
            post = Post.query.get(r.content_id)
            if post:
                item['contentTitle'] = post.title or ''
        elif r.content_type == 'live':
            from app.models.live import Live
            live = Live.query.get(r.content_id)
            if live:
                item['contentTitle'] = live.title
                item['contentImage'] = live.cover_image or ''

        items.append(item)

    return success_response({
        'list': items,
        'total': total,
        'page': page,
        'size': size,
        'hasMore': (page * size) < total,
    })


@admin_bp.route('/reviews/<review_id>', methods=['GET'])
@jwt_required
def review_detail(review_id):
    """
    审核详情
    GET /api/admin/reviews/<review_id>
    """
    review = ContentReview.query.get(review_id)
    if not review:
        return error_response(404, '审核记录不存在')

    submitter = User.query.get(review.submitter_id)
    result = {
        'reviewId': review.id,
        'contentType': review.content_type,
        'contentId': review.content_id,
        'submitterId': review.submitter_id,
        'submitterName': submitter.nickname if submitter else '',
        'status': review.status,
        'rejectReason': review.reject_reason or '',
        'createdAt': review.created_at,
        'reviewedAt': review.reviewed_at or 0,
        'contentDetail': None,
    }

    # 附加内容详情
    if review.content_type == 'product':
        from app.models.product import Product
        prod = Product.query.get(review.content_id)
        if prod:
            result['contentDetail'] = {
                'title': prod.title,
                'description': prod.description or '',
                'mainImages': prod.main_images or [],
                'price': float(prod.price),
                'shipFrom': prod.ship_from or '',
            }
    elif review.content_type == 'post':
        from app.models.community import Post
        post = Post.query.get(review.content_id)
        if post:
            result['contentDetail'] = {
                'title': post.title or '',
                'content': post.content or '',
                'images': post.images or [],
            }
    elif review.content_type == 'live':
        from app.models.live import Live
        live = Live.query.get(review.content_id)
        if live:
            result['contentDetail'] = {
                'title': live.title,
                'coverImage': live.cover_image or '',
                'intro': live.intro or '',
                'category': live.category or '',
            }

    return success_response(result)


@admin_bp.route('/reviews/<review_id>/approve', methods=['PUT'])
@jwt_required
def approve_review(review_id):
    """
    审核通过
    PUT /api/admin/reviews/<review_id>/approve
    """
    review = ContentReview.query.get(review_id)
    if not review:
        return error_response(404, '审核记录不存在')

    payload = g.current_user
    review.status = 'approved'
    review.reviewer_id = payload.get('admin_id') or payload.get('user_id')
    review.reviewed_at = int(time.time() * 1000)

    # 同步更新关联内容状态
    if review.content_type == 'product':
        from app.models.product import Product
        prod = Product.query.get(review.content_id)
        if prod:
            prod.status = 'approved'
    elif review.content_type == 'post':
        from app.models.community import Post
        post = Post.query.get(review.content_id)
        if post:
            post.status = 'normal'

    db.session.commit()
    return success_response({'reviewId': review_id, 'status': 'approved'})


@admin_bp.route('/reviews/<review_id>/reject', methods=['PUT'])
@jwt_required
def reject_review(review_id):
    """
    审核驳回
    PUT /api/admin/reviews/<review_id>/reject
    body: { reason }
    """
    review = ContentReview.query.get(review_id)
    if not review:
        return error_response(404, '审核记录不存在')

    body = request.get_json(silent=True) or {}
    reason = body.get('reason', '')
    if not reason:
        return error_response(400, '驳回原因不能为空')

    payload = g.current_user
    review.status = 'rejected'
    review.reject_reason = reason
    review.reviewer_id = payload.get('admin_id') or payload.get('user_id')
    review.reviewed_at = int(time.time() * 1000)

    # 同步更新关联内容状态
    if review.content_type == 'product':
        from app.models.product import Product
        prod = Product.query.get(review.content_id)
        if prod:
            prod.status = 'rejected'
            prod.reject_reason = reason
    elif review.content_type == 'post':
        from app.models.community import Post
        post = Post.query.get(review.content_id)
        if post:
            post.status = 'rejected'

    db.session.commit()
    return success_response({'reviewId': review_id, 'status': 'rejected', 'reason': reason})


@admin_bp.route('/reviews/pending-count', methods=['GET'])
@jwt_required
def pending_count():
    """
    待审核数量
    GET /api/admin/reviews/pending-count
    """
    count = ContentReview.query.filter_by(status='pending').count()
    return success_response({'count': count})


# ==================== API 管理 ====================

@admin_bp.route('/apis', methods=['GET'])
@jwt_required
def api_list():
    """
    API 列表
    GET /api/admin/apis?page=1&size=20
    """
    page = int(request.args.get('page', 1))
    size = int(request.args.get('size', 20))
    keyword = request.args.get('keyword', '')

    query = ApiInfo.query
    if keyword:
        query = query.filter(ApiInfo.path.contains(keyword))

    total = query.count()
    apis = query.offset((page - 1) * size).limit(size).all()

    items = [{
        'apiId': a.id,
        'path': a.path,
        'method': a.method,
        'description': a.description or '',
        'todayRequestCount': a.today_request_count,
        'errorRate': a.error_rate,
        'avgResponseTime': a.avg_response_time,
    } for a in apis]

    return success_response({
        'list': items,
        'total': total,
        'page': page,
        'size': size,
        'hasMore': (page * size) < total,
    })


@admin_bp.route('/apis/<api_id>', methods=['GET'])
@jwt_required
def api_detail(api_id):
    """API 详情聚合"""
    api = ApiInfo.query.get(api_id)
    if not api:
        return error_response(404, 'API 不存在')

    rate_limit = RateLimitConfig.query.filter_by(api_id=api_id).first()

    return success_response({
        'apiId': api.id,
        'path': api.path,
        'method': api.method,
        'description': api.description or '',
        'todayRequestCount': api.today_request_count,
        'errorRate': api.error_rate,
        'avgResponseTime': api.avg_response_time,
        'rateLimit': {
            'qpsLimit': rate_limit.qps_limit if rate_limit else 100,
        } if rate_limit else None,
    })


@admin_bp.route('/apis/<api_id>/rate-limit', methods=['GET'])
@jwt_required
def get_rate_limit(api_id):
    """获取限流配置"""
    rl = RateLimitConfig.query.filter_by(api_id=api_id).first()
    return success_response({
        'apiId': api_id,
        'qpsLimit': rl.qps_limit if rl else 100,
    })


@admin_bp.route('/apis/<api_id>/rate-limit', methods=['PUT'])
@jwt_required
def update_rate_limit(api_id):
    """更新限流配置"""
    body = request.get_json(silent=True) or {}
    qps = int(body.get('qpsLimit', 100))

    rl = RateLimitConfig.query.filter_by(api_id=api_id).first()
    if rl:
        rl.qps_limit = qps
    else:
        rl = RateLimitConfig(api_id=api_id, qps_limit=qps)
        db.session.add(rl)
    db.session.commit()

    return success_response({'apiId': api_id, 'qpsLimit': qps})


# ==================== 密钥管理 ====================

@admin_bp.route('/api-keys', methods=['GET'])
@jwt_required
def api_key_list():
    """密钥列表"""
    keys = ApiKey.query.order_by(ApiKey.created_at.desc()).all()
    items = [{
        'keyId': k.id,
        'appKey': k.app_key,
        'status': k.status,
        'createdAt': k.created_at,
    } for k in keys]
    return success_response({'list': items})


@admin_bp.route('/api-keys', methods=['POST'])
@jwt_required
def create_api_key():
    """创建密钥"""
    key = ApiKey(
        app_key=secrets.token_hex(16),
        app_secret=secrets.token_hex(32),
    )
    db.session.add(key)
    db.session.commit()

    return success_response({
        'keyId': key.id,
        'appKey': key.app_key,
        'appSecret': key.app_secret,
        'status': key.status,
    })


@admin_bp.route('/api-keys/<key_id>/revoke', methods=['PUT'])
@jwt_required
def revoke_api_key(key_id):
    """吊销密钥"""
    key = ApiKey.query.get(key_id)
    if not key:
        return error_response(404, '密钥不存在')

    key.status = 'revoked'
    db.session.commit()

    return success_response({'keyId': key_id, 'status': 'revoked'})
