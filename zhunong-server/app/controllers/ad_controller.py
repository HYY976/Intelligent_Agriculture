"""
ad_controller - 广告 API
  - GET /splash  开屏广告
"""

from flask import Blueprint, jsonify
from app.models.ranking import SplashAd
from app.utils.response import success_response

ad_bp = Blueprint('ad', __name__, url_prefix='/api/ad')


@ad_bp.route('/health', methods=['GET'])
def health():
    return jsonify({'code': 200, 'msg': 'ok', 'data': {'service': 'ad'}})


@ad_bp.route('/splash', methods=['GET'])
def splash_ad():
    """GET /api/ad/splash — 开屏广告（返回榜单 #1 的海报）"""
    ad = SplashAd.query.filter_by(rank=1).first()
    if ad:
        return success_response({
            'adId': ad.id,
            'posterUrl': ad.poster_url or '',
            'targetUrl': ad.target_url or '',
            'rankType': ad.rank_type,
        })
    return success_response(None)
