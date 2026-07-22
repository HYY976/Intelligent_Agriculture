"""
upload_controller - 文件上传 API
  - POST /image  图片上传
"""

import os
import uuid
import time
from flask import Blueprint, jsonify, request, current_app
from app.utils.response import success_response, error_response

upload_bp = Blueprint('upload', __name__, url_prefix='/api/upload')


@upload_bp.route('/health', methods=['GET'])
def health():
    return jsonify({'code': 200, 'msg': 'ok', 'data': {'service': 'upload'}})


@upload_bp.route('/image', methods=['POST'])
def upload_image():
    """
    图片上传（保存到 static/uploads/）
    POST /api/upload/image
    form-data: file=<image>
    """
    if 'file' not in request.files:
        return error_response(400, '未找到上传文件')

    file = request.files['file']
    if not file.filename:
        return error_response(400, '文件名为空')

    # 生成文件名
    ext = os.path.splitext(file.filename)[1] or '.jpg'
    filename = f'{int(time.time())}_{uuid.uuid4().hex[:8]}{ext}'

    # 确保目录存在
    upload_dir = os.path.join(current_app.static_folder or 'static', 'uploads')
    os.makedirs(upload_dir, exist_ok=True)

    filepath = os.path.join(upload_dir, filename)
    file.save(filepath)

    url = f'/static/uploads/{filename}'
    return success_response({'url': url, 'filename': filename})
