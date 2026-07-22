import uuid
import time
from app.extensions import db


class ChatSession(db.Model):
    __tablename__ = 'chat_sessions'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    type = db.Column(db.String(16), default='private')  # private/system
    user_a_id = db.Column(db.String(36), db.ForeignKey('users.id'))
    user_b_id = db.Column(db.String(36), db.ForeignKey('users.id'))
    last_message = db.Column(db.Text)
    last_message_at = db.Column(db.BigInteger)
    unread_count_a = db.Column(db.Integer, default=0)
    unread_count_b = db.Column(db.Integer, default=0)


class ChatMessage(db.Model):
    __tablename__ = 'chat_messages'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    session_id = db.Column(db.String(36), db.ForeignKey('chat_sessions.id'), nullable=False)
    sender_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    receiver_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    content_type = db.Column(db.String(16), default='text')  # text/image/emoji
    content = db.Column(db.Text)
    is_read = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.BigInteger, default=lambda: int(time.time() * 1000))
