"""
message_controller - 消息模块 API
  - GET  /sessions      会话列表
  - GET  /history       历史消息
  - POST /send          发送消息
"""

import time
from flask import Blueprint, jsonify, request, g
from app.extensions import db
from app.models.message import ChatSession, ChatMessage
from app.models.user import User
from app.utils.response import success_response, error_response
from app.utils.decorators import jwt_required

message_bp = Blueprint('message', __name__, url_prefix='/api/message')


@message_bp.route('/health', methods=['GET'])
def health():
    return jsonify({'code': 200, 'msg': 'ok', 'data': {'service': 'message'}})


@message_bp.route('/sessions', methods=['GET'])
@jwt_required
def session_list():
    """GET /api/message/sessions"""
    payload = g.current_user
    user_id = payload.get('user_id')

    # 查找与当前用户相关的会话
    sessions = ChatSession.query.filter(
        (ChatSession.user_a_id == user_id) | (ChatSession.user_b_id == user_id)
    ).order_by(ChatSession.last_message_at.desc()).all()

    items = []
    for s in sessions:
        # 确定对方
        other_id = s.user_b_id if s.user_a_id == user_id else s.user_a_id
        other = User.query.get(other_id)

        unread = s.unread_count_a if s.user_a_id == user_id else s.unread_count_b

        items.append({
            'sessionId': s.id,
            'type': s.type,
            'otherId': other_id,
            'otherName': other.nickname if other else '',
            'otherAvatar': other.avatar if other else '',
            'lastMessage': s.last_message or '',
            'lastMessageAt': s.last_message_at or 0,
            'unreadCount': unread,
        })

    return success_response({'list': items})


@message_bp.route('/history', methods=['GET'])
@jwt_required
def message_history():
    """GET /api/message/history?sessionId=&page=1&size=50"""
    session_id = request.args.get('sessionId', '')
    page = int(request.args.get('page', 1))
    size = int(request.args.get('size', 50))

    if not session_id:
        return error_response(400, 'sessionId 不能为空')

    query = ChatMessage.query.filter_by(session_id=session_id)
    total = query.count()
    messages = query.order_by(ChatMessage.created_at.asc()).offset((page - 1) * size).limit(size).all()

    items = []
    for m in messages:
        sender = User.query.get(m.sender_id)
        items.append({
            'messageId': m.id,
            'sessionId': m.session_id,
            'senderId': m.sender_id,
            'senderName': sender.nickname if sender else '',
            'senderAvatar': sender.avatar if sender else '',
            'contentType': m.content_type,
            'content': m.content,
            'isRead': m.is_read,
            'createdAt': m.created_at,
        })

    return success_response({
        'list': items,
        'total': total,
        'page': page,
        'size': size,
        'hasMore': (page * size) < total,
    })


@message_bp.route('/send', methods=['POST'])
@jwt_required
def send_message():
    """
    POST /api/message/send
    body: { sessionId, receiverId, content, contentType? }
    """
    payload = g.current_user
    sender_id = payload.get('user_id')
    body = request.get_json(silent=True) or {}

    session_id = body.get('sessionId', '')
    receiver_id = body.get('receiverId', '')
    content = body.get('content', '')
    content_type = body.get('contentType', 'text')

    if not content:
        return error_response(400, '消息内容不能为空')

    msg = ChatMessage(
        session_id=session_id,
        sender_id=sender_id,
        receiver_id=receiver_id,
        content_type=content_type,
        content=content,
    )
    db.session.add(msg)

    # 更新会话
    if session_id:
        session = ChatSession.query.get(session_id)
        if session:
            session.last_message = content
            session.last_message_at = int(time.time() * 1000)
            # 更新未读数
            if session.user_a_id == receiver_id:
                session.unread_count_a = (session.unread_count_a or 0) + 1
            else:
                session.unread_count_b = (session.unread_count_b or 0) + 1

    db.session.commit()
    return success_response({'messageId': msg.id, 'createdAt': msg.created_at})
