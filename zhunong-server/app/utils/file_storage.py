import os
import time
from werkzeug.utils import secure_filename
from flask import current_app


def save_file(file, sub_dir=''):
    """保存上传文件到 app/static/uploads/，返回可访问 URL 路径"""
    upload_folder = current_app.config.get('UPLOAD_FOLDER', 'app/static/uploads')
    target_dir = os.path.join(upload_folder, sub_dir) if sub_dir else upload_folder
    os.makedirs(target_dir, exist_ok=True)

    filename = secure_filename(file.filename)
    ts = int(time.time() * 1000)
    saved_name = '%s_%s' % (ts, filename)
    file_path = os.path.join(target_dir, saved_name)
    file.save(file_path)

    if sub_dir:
        return '/static/uploads/%s/%s' % (sub_dir, saved_name)
    return '/static/uploads/%s' % saved_name
