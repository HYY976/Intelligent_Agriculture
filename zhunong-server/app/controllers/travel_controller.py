"""
travel_controller - 文旅模块 API
  - GET /pois         POI 检索
  - GET /pois/<id>    POI 详情
  - GET /routes       路线推荐
"""

import math
from flask import Blueprint, jsonify, request
from app.utils.response import success_response, error_response

travel_bp = Blueprint('travel', __name__, url_prefix='/api/travel')


@travel_bp.route('/health', methods=['GET'])
def health():
    return jsonify({'code': 200, 'msg': 'ok', 'data': {'service': 'travel'}})


@travel_bp.route('/pois', methods=['GET'])
def poi_list():
    """
    POI 检索（Mock 数据）
    GET /api/travel/pois?keyword=&lat=&lng=&page=1&size=20
    """
    keyword = request.args.get('keyword', '')
    page = int(request.args.get('page', 1))
    size = int(request.args.get('size', 20))

    # Mock POI 数据
    mock_pois = [
        {'poiId': 'poi001', 'name': '黄鹤楼', 'category': '景点', 'address': '武汉市武昌区蛇山之巅', 'lat': 30.5453, 'lng': 114.3025, 'rating': 4.8, 'commentCount': 12560},
        {'poiId': 'poi002', 'name': '东湖绿道', 'category': '景点', 'address': '武汉市洪山区东湖畔', 'lat': 30.5500, 'lng': 114.4200, 'rating': 4.7, 'commentCount': 8930},
        {'poiId': 'poi003', 'name': '户部巷', 'category': '美食', 'address': '武汉市武昌区自由路', 'lat': 30.5430, 'lng': 114.3010, 'rating': 4.5, 'commentCount': 15670},
        {'poiId': 'poi004', 'name': '木兰草原', 'category': '景点', 'address': '武汉市黄陂区', 'lat': 30.8800, 'lng': 114.3500, 'rating': 4.6, 'commentCount': 5430},
        {'poiId': 'poi005', 'name': '武汉大学', 'category': '景点', 'address': '武汉市武昌区珞珈山', 'lat': 30.5400, 'lng': 114.3600, 'rating': 4.9, 'commentCount': 23450},
        {'poiId': 'poi006', 'name': '江汉路步行街', 'category': '购物', 'address': '武汉市江汉区', 'lat': 30.5810, 'lng': 114.2880, 'rating': 4.4, 'commentCount': 9870},
        {'poiId': 'poi007', 'name': '归元寺', 'category': '景点', 'address': '武汉市汉阳区翠微路', 'lat': 30.5460, 'lng': 114.2660, 'rating': 4.5, 'commentCount': 4560},
        {'poiId': 'poi008', 'name': '昙华林', 'category': '文创', 'address': '武汉市武昌区', 'lat': 30.5490, 'lng': 114.3050, 'rating': 4.6, 'commentCount': 6780},
    ]

    if keyword:
        mock_pois = [p for p in mock_pois if keyword in p['name'] or keyword in p['category']]

    start = (page - 1) * size
    end = start + size
    items = mock_pois[start:end]

    return success_response({
        'list': items,
        'total': len(mock_pois),
        'page': page,
        'size': size,
        'hasMore': end < len(mock_pois),
    })


@travel_bp.route('/pois/<poi_id>', methods=['GET'])
def poi_detail(poi_id):
    """POI 详情"""
    mock_detail = {
        'poi001': {'poiId': 'poi001', 'name': '黄鹤楼', 'category': '景点', 'address': '武汉市武昌区蛇山之巅', 'lat': 30.5453, 'lng': 114.3025, 'rating': 4.8, 'commentCount': 12560, 'intro': '天下江山第一楼，与岳阳楼、滕王阁并称江南三大名楼。', 'openTime': '08:00-18:00', 'ticketPrice': 70},
        'poi002': {'poiId': 'poi002', 'name': '东湖绿道', 'category': '景点', 'address': '武汉市洪山区东湖畔', 'lat': 30.5500, 'lng': 114.4200, 'rating': 4.7, 'commentCount': 8930, 'intro': '全长101.98公里的环湖绿道，骑行漫步皆宜。', 'openTime': '全天开放', 'ticketPrice': 0},
    }
    detail = mock_detail.get(poi_id)
    if not detail:
        return error_response(404, 'POI 不存在')
    return success_response(detail)


@travel_bp.route('/routes', methods=['GET'])
def route_list():
    """
    路线推荐（Mock）
    GET /api/travel/routes
    """
    routes = [
        {'routeId': 'r001', 'name': '武汉经典一日游', 'description': '黄鹤楼 → 户部巷 → 东湖绿道', 'pois': ['poi001', 'poi003', 'poi002'], 'duration': '8小时', 'distance': 15.2},
        {'routeId': 'r002', 'name': '文艺小众半日游', 'description': '昙华林 → 江汉路步行街', 'pois': ['poi008', 'poi006'], 'duration': '4小时', 'distance': 5.8},
    ]
    return success_response({'list': routes})
