from flask import jsonify


def success_response(data=None, msg='success', code=200):
    return jsonify({'code': code, 'msg': msg, 'data': data}), 200


def error_response(code, msg):
    return jsonify({'code': code, 'msg': msg, 'data': None}), 200
