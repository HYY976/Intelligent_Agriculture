"""
live_controller - 直播模块 API
  - GET  /list          直播列表
  - GET  /<id>          直播详情
  - GET  /gifts         礼物列表
  - GET  /<id>/comments 直播评论
"""

from flask import Blueprint, jsonify, request
from app.extensions import db
from app.models.live import Live
from app.models.user import User, FarmerProfile
from app.models.gift import Gift
from app.utils.response import success_response, error_response

live_bp = Blueprint('live', __name__, url_prefix='/api/live')


@live_bp.route('/health', methods=['GET'])
def health():
    return jsonify({'code': 200, 'msg': 'ok', 'data': {'service': 'live'}})


@live_bp.route('/list', methods=['GET'])
def live_list():
    """
    GET /api/live/list?page=1&size=20&status=
    """
    page = int(request.args.get('page', 1))
    size = int(request.args.get('size', 20))
    status = request.args.get('status', '')

    query = Live.query
    if status:
        query = query.filter_by(status=status)

    total = query.count()
    lives = query.order_by(Live.created_at.desc()).offset((page - 1) * size).limit(size).all()

    items = []
    for l in lives:
        farmer = User.query.get(l.farmer_id)
        fp = FarmerProfile.query.filter_by(user_id=l.farmer_id).first()
        items.append({
            'liveId': l.id,
            'farmerId': l.farmer_id,
            'farmerName': fp.shop_name if fp else (farmer.nickname if farmer else ''),
            'farmerAvatar': farmer.avatar if farmer else '',
            'title': l.title,
            'coverImage': l.cover_image or '',
            'category': l.category or '',
            'status': l.status,
            'startTime': l.start_time or 0,
            'endTime': l.end_time or 0,
            'totalViewUv': l.total_view_uv,
            'productBag': l.product_bag or [],
        })

    return success_response({
        'list': items,
        'total': total,
        'page': page,
        'size': size,
        'hasMore': (page * size) < total,
    })


@live_bp.route('/<live_id>', methods=['GET'])
def live_detail(live_id):
    """GET /api/live/<live_id>"""
    l = Live.query.get(live_id)
    if not l:
        return error_response(404, '直播不存在')

    farmer = User.query.get(l.farmer_id)
    fp = FarmerProfile.query.filter_by(user_id=l.farmer_id).first()

    return success_response({
        'liveId': l.id,
        'farmerId': l.farmer_id,
        'farmerName': fp.shop_name if fp else (farmer.nickname if farmer else ''),
        'farmerAvatar': farmer.avatar if farmer else '',
        'title': l.title,
        'coverImage': l.cover_image or '',
        'category': l.category or '',
        'intro': l.intro or '',
        'status': l.status,
        'startTime': l.start_time or 0,
        'endTime': l.end_time or 0,
        'totalViewUv': l.total_view_uv,
        'totalGiftIncome': float(l.total_gift_income or 0),
        'productBag': l.product_bag or [],
    })


@live_bp.route('/gifts', methods=['GET'])
def gift_list():
    """GET /api/live/gifts"""
    gifts = Gift.query.all()
    items = [{
        'giftId': g.id,
        'name': g.name,
        'icon': g.icon or '',
        'price': float(g.price),
    } for g in gifts]
    return success_response({'list': items})


@live_bp.route('/<live_id>/comments', methods=['GET'])
def live_comments(live_id):
    """GET /api/live/<live_id>/comments?page=1&size=50"""
    # 直播评论暂返回空列表
    return success_response({'list': [], 'total': 0})
