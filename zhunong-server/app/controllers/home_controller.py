"""
home_controller - 首页 API
  - GET /recommend  首页推荐流（分页）
  - GET /banner     Banner 列表
"""

import time
from flask import Blueprint, jsonify, request
from app.extensions import db
from app.models.product import Product, Category
from app.models.user import User, FarmerProfile
from app.utils.response import success_response, error_response

home_bp = Blueprint('home', __name__, url_prefix='/api/home')


@home_bp.route('/health', methods=['GET'])
def health():
    return jsonify({'code': 200, 'msg': 'ok', 'data': {'service': 'home'}})


@home_bp.route('/recommend', methods=['GET'])
def recommend():
    """
    首页推荐流（分页，返回已上架商品）
    GET /api/homeF/home/recommend?page=1&size=20
    """
    page = int(request.args.get('page', 1))
    size = int(request.args.get('size', 20))

    query = Product.query.filter_by(status='approved')
    total = query.count()
    products = query.order_by(Product.monthly_sales.desc()).offset((page - 1) * size).limit(size).all()

    items = []
    for p in products:
        farmer = User.query.get(p.farmer_id)
        fp = FarmerProfile.query.filter_by(user_id=p.farmer_id).first() if farmer else None
        items.append({
            'productId': p.id,
            'title': p.title,
            'mainImage': (p.main_images or [''])[0] if p.main_images else '',
            'price': float(p.price),
            'monthlySales': p.monthly_sales,
            'farmerName': fp.shop_name if fp else (farmer.nickname if farmer else ''),
            'shipFrom': p.ship_from or '',
            'monthlyGmv': float(p.monthly_gmv or 0),
        })

    return success_response({
        'list': items,
        'total': total,
        'page': page,
        'size': size,
        'hasMore': (page * size) < total,
    })


@home_bp.route('/banner', methods=['GET'])
def banner_list():
    """
    Banner 列表（Mock 3 条固定 Banner）
    GET /api/home/banner
    """
    banners = [
        {'id': 'b1', 'image': 'banner_1', 'title': '新鲜水果 直采直发', 'linkType': 'category', 'linkId': 'c111'},
        {'id': 'b2', 'image': 'banner_2', 'title': '助农直播 精彩不停', 'linkType': 'live', 'linkId': ''},
        {'id': 'b3', 'image': 'banner_3', 'title': '乡村文旅 周末好去处', 'linkType': 'travel', 'linkId': ''},
    ]
    return success_response(banners)
