"""
farmer_controller - 农户卖家端 API
  - POST /login           卖家登录
  - POST /sms_code        发送验证码（Mock）
  - GET  /profile         卖家信息
  - PUT  /profile         更新店铺信息
  - POST /certification   提交资质认证
  - GET  /products        卖家商品列表
  - PUT  /product/status  上下架
  - DELETE /product/delete 删除商品
  - POST /product/publish 发布新商品
  - PUT  /product/update  编辑商品
  - GET  /fans            粉丝列表
  - GET  /lives           直播管理历史
  - POST /live/create     开播创建
  - POST /live/end        结束直播
"""

import time
import uuid
from flask import Blueprint, jsonify, request, g
from werkzeug.security import generate_password_hash
from app.extensions import db
from app.models.user import User, FarmerProfile, CertificationInfo
from app.models.product import Product, ProductSku, Category
from app.models.live import Live
from app.models.follow import Follow
from app.utils.response import success_response, error_response
from app.utils.jwt_util import generate_user_token
from app.utils.decorators import jwt_required

farmer_bp = Blueprint('farmer', __name__, url_prefix='/api/farmer')


@farmer_bp.route('/health', methods=['GET'])
def health():
    return jsonify({'code': 200, 'msg': 'ok', 'data': {'service': 'farmer'}})


# ==================== 登录 ====================

@farmer_bp.route('/sms_code', methods=['POST'])
def send_sms_code():
    """发送验证码（Mock）"""
    body = request.get_json(silent=True) or {}
    phone = body.get('phone', '')
    if not phone or len(phone) != 11:
        return error_response(400, '手机号格式不正确')
    return success_response(None, msg='验证码已发送')


@farmer_bp.route('/login', methods=['POST'])
def login():
    """
    卖家手机号+验证码登录（任意6位码通过）
    POST /api/farmer/login
    body: { phone, code }
    return: { token, userInfo }
    """
    body = request.get_json(silent=True) or {}
    phone = body.get('phone', '')
    code = body.get('code', '')

    if not phone or len(phone) != 11:
        return error_response(400, '手机号格式不正确')
    if not code or len(code) != 6:
        return error_response(400, '验证码为6位数字')

    user = User.query.filter_by(phone=phone, user_type='farmer').first()
    if user is None:
        # 首次登录自动注册为农户
        user = User(
            phone=phone,
            nickname=f'农户{phone[-4:]}',
            password_hash=generate_password_hash('123456'),
            user_type='farmer',
        )
        db.session.add(user)
        db.session.flush()
        # 自动创建 FarmerProfile
        fp = FarmerProfile(
            user_id=user.id,
            shop_name=f'农户{phone[-4:]}的店铺',
        )
        db.session.add(fp)
        db.session.commit()

    if user.status == 'banned':
        return error_response(403, '账号已被封禁')

    user.last_login_at = int(time.time() * 1000)
    db.session.commit()

    token = generate_user_token(user.id, user.user_type)

    # 附加农户信息
    fp = FarmerProfile.query.filter_by(user_id=user.id).first()
    user_info = {
        'userId': user.id,
        'phone': user.phone,
        'nickname': user.nickname or '',
        'avatar': user.avatar or '',
        'userType': 'farmer',
        'status': user.status,
        'createdAt': user.created_at,
        'lastLoginAt': user.last_login_at,
        'certStatus': fp.certification_status if fp else 'none',
    }

    return success_response({'token': token, 'userInfo': user_info})


# ==================== 卖家信息 ====================

@farmer_bp.route('/profile', methods=['GET'])
@jwt_required
def get_profile():
    """GET /api/farmer/profile"""
    payload = g.current_user
    user_id = payload.get('user_id')
    user = User.query.get(user_id)
    if not user:
        return error_response(404, '用户不存在')

    fp = FarmerProfile.query.filter_by(user_id=user_id).first()

    return success_response({
        'userId': user.id,
        'phone': user.phone,
        'nickname': user.nickname or '',
        'avatar': user.avatar or '',
        'shopName': fp.shop_name if fp else '',
        'shopLogo': fp.shop_logo if fp else '',
        'shopIntro': fp.shop_intro if fp else '',
        'certificationStatus': fp.certification_status if fp else 'none',
        'totalRevenue': float(fp.total_revenue or 0) if fp else 0,
        'availableBalance': float(fp.available_balance or 0) if fp else 0,
        'fansCount': fp.fans_count if fp else 0,
        'followCount': fp.follow_count if fp else 0,
    })


@farmer_bp.route('/profile', methods=['PUT'])
@jwt_required
def update_profile():
    """PUT /api/farmer/profile  body: { shopName?, shopIntro?, shopLogo? }"""
    payload = g.current_user
    user_id = payload.get('user_id')

    body = request.get_json(silent=True) or {}
    user = User.query.get(user_id)
    if 'nickname' in body:
        user.nickname = body['nickname']
    if 'avatar' in body:
        user.avatar = body['avatar']

    fp = FarmerProfile.query.filter_by(user_id=user_id).first()
    if fp:
        if 'shopName' in body:
            fp.shop_name = body['shopName']
        if 'shopIntro' in body:
            fp.shop_intro = body['shopIntro']
        if 'shopLogo' in body:
            fp.shop_logo = body['shopLogo']

    db.session.commit()
    return success_response(True)


@farmer_bp.route('/certification', methods=['POST'])
@jwt_required
def submit_certification():
    """
    提交资质认证（Mock：直接 approved）
    POST /api/farmer/certification
    body: { realName, idCardNo, idCardFrontImg?, idCardBackImg?, farmerCertImg? }
    """
    payload = g.current_user
    user_id = payload.get('user_id')
    body = request.get_json(silent=True) or {}

    ci = CertificationInfo(
        farmer_id=user_id,
        real_name=body.get('realName', ''),
        id_card_no=body.get('idCardNo', ''),
        id_card_front_img=body.get('idCardFrontImg', ''),
        id_card_back_img=body.get('idCardBackImg', ''),
        farmer_cert_img=body.get('farmerCertImg', ''),
        status='approved',
        reviewed_at=int(time.time() * 1000),
    )
    db.session.add(ci)

    fp = FarmerProfile.query.filter_by(user_id=user_id).first()
    if fp:
        fp.certification_status = 'approved'
        fp.real_name = body.get('realName', '')

    db.session.commit()
    return success_response('approved')


# ==================== 商品管理 ====================

@farmer_bp.route('/products', methods=['GET'])
@jwt_required
def product_list():
    """GET /api/farmer/products?page=1&size=20&status="""
    payload = g.current_user
    farmer_id = payload.get('user_id')
    page = int(request.args.get('page', 1))
    size = int(request.args.get('size', 20))
    status = request.args.get('status', '')

    query = Product.query.filter_by(farmer_id=farmer_id)
    if status:
        query = query.filter_by(status=status)

    total = query.count()
    products = query.order_by(Product.created_at.desc()).offset((page - 1) * size).limit(size).all()

    items = []
    for p in products:
        cat = Category.query.get(p.category_id) if p.category_id else None
        items.append({
            'productId': p.id,
            'title': p.title,
            'mainImages': p.main_images or [],
            'price': float(p.price),
            'stock': p.stock,
            'monthlySales': p.monthly_sales,
            'status': p.status,
            'categoryName': cat.name if cat else '',
            'createdAt': p.created_at,
        })

    return success_response({
        'list': items,
        'total': total,
        'page': page,
        'size': size,
        'hasMore': (page * size) < total,
    })


@farmer_bp.route('/product/status', methods=['PUT'])
@jwt_required
def update_product_status():
    """
    商品上下架
    PUT /api/farmer/product/status
    body: { productId, status: 'approved'|'off_shelf' }
    """
    body = request.get_json(silent=True) or {}
    product_id = body.get('productId', '')
    new_status = body.get('status', '')

    product = Product.query.get(product_id)
    if not product:
        return error_response(404, '商品不存在')

    product.status = new_status
    db.session.commit()
    return success_response(True)


@farmer_bp.route('/product/delete', methods=['DELETE'])
@jwt_required
def delete_product():
    """DELETE /api/farmer/product/delete  body: { productId }"""
    body = request.get_json(silent=True) or {}
    product_id = body.get('productId', '')
    product = Product.query.get(product_id)
    if product:
        db.session.delete(product)
        db.session.commit()
    return success_response(True)


@farmer_bp.route('/product/publish', methods=['POST'])
@jwt_required
def publish_product():
    """
    发布新商品
    POST /api/farmer/product/publish
    body: { title, categoryId, mainImages, description, price, stock, shipFrom, ... }
    """
    payload = g.current_user
    farmer_id = payload.get('user_id')
    body = request.get_json(silent=True) or {}

    product = Product(
        farmer_id=farmer_id,
        title=body.get('title', ''),
        category_id=body.get('categoryId', ''),
        main_images=body.get('mainImages', []),
        description=body.get('description', ''),
        price=body.get('price', 0),
        stock=body.get('stock', 0),
        ship_from=body.get('shipFrom', ''),
        freight_template=body.get('freightTemplate', '包邮'),
        status='pending_review',
    )
    db.session.add(product)
    db.session.flush()

    # 创建审核记录
    from app.models.review import ContentReview
    review = ContentReview(
        content_type='product',
        content_id=product.id,
        submitter_id=farmer_id,
        status='pending',
    )
    db.session.add(review)
    db.session.commit()

    return success_response({'productId': product.id, 'status': 'pending_review'})


@farmer_bp.route('/product/update', methods=['PUT'])
@jwt_required
def update_product():
    """PUT /api/farmer/product/update  body: { productId, title?, ... }"""
    body = request.get_json(silent=True) or {}
    product_id = body.get('productId', '')
    product = Product.query.get(product_id)
    if not product:
        return error_response(404, '商品不存在')

    for field in ['title', 'description', 'price', 'stock', 'shipFrom', 'freightTemplate']:
        if field in body:
            setattr(product, field, body[field])
    if 'mainImages' in body:
        product.main_images = body['mainImages']
    if 'categoryId' in body:
        product.category_id = body['categoryId']

    product.updated_at = int(time.time() * 1000)
    db.session.commit()
    return success_response(True)


# ==================== 粉丝管理 ====================

@farmer_bp.route('/fans', methods=['GET'])
@jwt_required
def fans_list():
    """GET /api/farmer/fans?page=1&size=20"""
    payload = g.current_user
    farmer_id = payload.get('user_id')
    page = int(request.args.get('page', 1))
    size = int(request.args.get('size', 20))

    query = Follow.query.filter_by(following_id=farmer_id)
    total = query.count()
    follows = query.order_by(Follow.created_at.desc()).offset((page - 1) * size).limit(size).all()

    items = []
    for f in follows:
        fan = User.query.get(f.follower_id)
        if fan:
            items.append({
                'fanId': fan.id,
                'nickname': fan.nickname or '',
                'avatar': fan.avatar or '',
                'followedAt': f.created_at,
            })

    return success_response({
        'list': items,
        'total': total,
        'page': page,
        'size': size,
        'hasMore': (page * size) < total,
    })


# ==================== 直播管理 ====================

@farmer_bp.route('/lives', methods=['GET'])
@jwt_required
def live_list():
    """GET /api/farmer/lives?page=1&size=20"""
    payload = g.current_user
    farmer_id = payload.get('user_id')
    page = int(request.args.get('page', 1))
    size = int(request.args.get('size', 20))

    query = Live.query.filter_by(farmer_id=farmer_id)
    total = query.count()
    lives = query.order_by(Live.created_at.desc()).offset((page - 1) * size).limit(size).all()

    items = []
    for l in lives:
        items.append({
            'liveId': l.id,
            'title': l.title,
            'coverImage': l.cover_image or '',
            'category': l.category or '',
            'status': l.status,
            'startTime': l.start_time or 0,
            'endTime': l.end_time or 0,
            'totalViewUv': l.total_view_uv,
            'totalGiftIncome': float(l.total_gift_income or 0),
        })

    return success_response({
        'list': items,
        'total': total,
        'page': page,
        'size': size,
        'hasMore': (page * size) < total,
    })


@farmer_bp.route('/live/create', methods=['POST'])
@jwt_required
def create_live():
    """
    开播创建
    POST /api/farmer/live/create
    body: { title, coverImage, category?, intro?, productBag? }
    """
    payload = g.current_user
    farmer_id = payload.get('user_id')
    body = request.get_json(silent=True) or {}

    now_ms = int(time.time() * 1000)
    live = Live(
        farmer_id=farmer_id,
        title=body.get('title', ''),
        cover_image=body.get('coverImage', ''),
        category=body.get('category', ''),
        intro=body.get('intro', ''),
        product_bag=body.get('productBag', []),
        status='living',
        start_time=now_ms,
    )
    db.session.add(live)
    db.session.commit()

    return success_response({'liveId': live.id, 'status': 'living'})


@farmer_bp.route('/live/end', methods=['POST'])
@jwt_required
def end_live():
    """
    结束直播
    POST /api/farmer/live/end
    body: { liveId }
    """
    body = request.get_json(silent=True) or {}
    live_id = body.get('liveId', '')
    live = Live.query.get(live_id)
    if not live:
        return error_response(404, '直播不存在')

    live.status = 'ended'
    live.end_time = int(time.time() * 1000)
    db.session.commit()

    return success_response({'liveId': live_id, 'status': 'ended'})
