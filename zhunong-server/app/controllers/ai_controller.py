"""
ai_controller - AI 服务 API（Mock）
  - POST /copywrite  AI 文案生成（返回预设模板）
  - POST /poster    AI 海报生成（返回商品首图）
"""

from flask import Blueprint, jsonify, request
from app.utils.response import success_response, error_response

ai_bp = Blueprint('ai', __name__, url_prefix='/api/ai')


@ai_bp.route('/health', methods=['GET'])
def health():
    return jsonify({'code': 200, 'msg': 'ok', 'data': {'service': 'ai'}})


@ai_bp.route('/copywrite', methods=['POST'])
def generate_copywrite():
    """
    AI 文案生成（Mock：返回3个预设模板文案）
    POST /api/ai/copywrite
    body: { title, category? }
    """
    body = request.get_json(silent=True) or {}
    title = body.get('title', '商品')

    descriptions = [
        f'{title} - 新鲜直达，品质保证。产地直供，从田间到餐桌，只为让你尝到最纯正的味道。',
        f'{title} - 农家直供，绿色健康。无农药无化肥，自然生长，营养丰富，全家放心吃。',
        f'{title} - 当季采摘，营养美味。每一口都是大自然的馈赠，新鲜看得见，好味吃得出。',
    ]

    return success_response({
        'descriptions': descriptions,
        'usage': 'mock',
    })


@ai_bp.route('/poster', methods=['POST'])
def generate_poster():
    """
    AI 海报生成（Mock：返回商品首图 URL）
    POST /api/ai/poster
    body: { productId, mainImage }
    """
    body = request.get_json(silent=True) or {}
    main_image = body.get('mainImage', '')

    return success_response({
        'posterUrl': main_image or 'ai_poster_default',
        'usage': 'mock',
    })
