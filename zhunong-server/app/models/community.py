import uuid
import time
from app.extensions import db


class Topic(db.Model):
    __tablename__ = 'topics'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = db.Column(db.String(64), nullable=False)
    sort_order = db.Column(db.Integer, default=0)
    is_preset = db.Column(db.Boolean, default=False)


class Post(db.Model):
    __tablename__ = 'posts'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    author_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    author_type = db.Column(db.String(16), nullable=False)  # user/farmer
    topic_id = db.Column(db.String(36), db.ForeignKey('topics.id'))
    title = db.Column(db.String(128))
    content = db.Column(db.Text)
    images = db.Column(db.JSON)
    like_count = db.Column(db.Integer, default=0)
    comment_count = db.Column(db.Integer, default=0)
    favorite_count = db.Column(db.Integer, default=0)
    share_count = db.Column(db.Integer, default=0)
    status = db.Column(db.String(16), default='normal')  # normal/reviewing/rejected/deleted
    created_at = db.Column(db.BigInteger, default=lambda: int(time.time() * 1000))


class Comment(db.Model):
    __tablename__ = 'comments'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    post_id = db.Column(db.String(36), db.ForeignKey('posts.id'), nullable=False)
    parent_id = db.Column(db.String(36), db.ForeignKey('comments.id'))
    author_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    author_type = db.Column(db.String(16), nullable=False)  # user/farmer
    content = db.Column(db.Text, nullable=False)
    like_count = db.Column(db.Integer, default=0)
    created_at = db.Column(db.BigInteger, default=lambda: int(time.time() * 1000))
