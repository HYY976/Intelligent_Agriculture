"""
rank_controller - 排行榜 API
  - GET /product  商品月度排行
  - GET /live     直播月度排行
"""

import time
from flask import Blueprint, jsonify, request
from app.extensions import db
from app.models.ranking import ProductRank, LiveRank
from app.models.product import Product
from app.models.live import Live
from app.models.user import User, FarmerProfile
from app.utils.response import success_response

rank_bp = Blueprint('rank', __name__, url_prefix='/api/rank')


@rank_bp.route('/health', methods=['GET'])
def health():
    return jsonify({'code': 200, 'msg': 'ok', 'data': {'service': 'rank'}})


@rank_bp.route('/product', methods=['GET'])
def product_rank():
    """GET /api/rank/product?month=2026-07"""
    month = request.args.get('month', time.strftime('%Y-%m'))
    ranks = ProductRank.query.filter_by(month=month).order_by(ProductRank.rank).limit(10).all()

    items = []
    for r in ranks:
        p = Product.query.get(r.product_id)
        farmer = User.query.get(r.farmer_id) if r.farmer_id else None
        fp = FarmerProfile.query.filter_by(user_id=r.farmer_id).first() if farmer else None
        items.append({
            'rank': r.rank,
            'productId': r.product_id,
            'title': p.title if p else '',
            'mainImage': (p.main_images or [''])[0] if p and p.main_images else '',
            'farmerName': fp.shop_name if fp else (farmer.nickname if farmer else ''),
            'monthlyGmv': float(r.monthly_gmv or 0),
        })

    return success_response({'list': items})


@rank_bp.route('/live', methods=['GET'])
def live_rank():
    """GET /api/rank/live?month=2026-07"""
    month = request.args.get('month', time.strftime('%Y-%m'))
    ranks = LiveRank.query.filter_by(month=month).order_by(LiveRank.rank).limit(10).all()

    items = []
    for r in ranks:
        l = Live.query.get(r.live_id)
        farmer = User.query.get(r.farmer_id) if r.farmer_id else None
        fp = FarmerProfile.query.filter_by(user_id=r.farmer_id).first() if farmer else None
        items.append({
            'rank': r.rank,
            'liveId': r.live_id,
            'title': l.title if l else '',
            'farmerName': fp.shop_name if fp else (farmer.nickname if farmer else ''),
            'monthlyIncome': float(r.monthly_income or 0),
        })

    return success_response({'list': items})
