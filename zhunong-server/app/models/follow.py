import uuid
import time
from app.extensions import db


class Follow(db.Model):
    __tablename__ = 'follows'
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    follower_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    following_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    created_at = db.Column(db.BigInteger, default=lambda: int(time.time() * 1000))
